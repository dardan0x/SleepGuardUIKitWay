import AVFoundation
import SleepDomain
import SleepLogging

/// `AudioCapture` over AVAudioEngine, as SleepGuard's recorder captures:
///
/// - **A direct tap on the input node.** No output path: an earlier graph that
///   routed the input to the mixer also fed the speaker, and a mic that hears
///   the speaker forms a feedback loop.
/// - **`.measurement` mode.** No automatic gain or voice processing, so quiet
///   snoring isn't turned down, and the full band reaches the analysis.
/// - **A new engine at every start.** An engine with a tap can't be restarted
///   reliably, and a new route can change the input format.
/// - **Interruptions are reported.** A call stops the engine and sends
///   `interrupted`; listening comes back when the interruption ends (with or
///   without `.shouldResume`), after a media-services reset or a route
///   change, and sends `resumed`. A resume that fails is logged and retried
///   at the next of those events.
///
/// Buffer work happens on the audio thread in `CaptureProcessor`.
@MainActor
final class EngineAudioCapture: AudioCapture {
  private let clipsDirectory: URL
  private let processor = CaptureProcessor()
  private var engine: AVAudioEngine?
  private var format: AVAudioFormat?
  private var continuation: AsyncStream<CaptureEvent>.Continuation?
  private var clipURL: URL?
  /// The engine kept running during the start delay (no listening).
  private var warmEngine: AVAudioEngine?
  private var rawAudioFileName: String?
  private var observers: [NSObjectProtocol] = []
  /// Paused for the Snore Interrupter's melody: nothing restarts the engine
  /// until `resume`.
  private var isPaused = false
  /// The system took the microphone (`interrupted` was sent); cleared by the
  /// resume that sends `resumed`.
  private var isInterrupted = false

  init(clipsDirectory: URL) {
    self.clipsDirectory = clipsDirectory
  }

  var isListening: Bool {
    continuation != nil
  }

  var isRunning: Bool {
    engine?.isRunning == true
  }

  func requestPermission() async -> Bool {
    await AVAudioApplication.requestRecordPermission()
  }

  func warmUp() throws {
    guard warmEngine == nil, !isListening else { return }
    try activateSession()
    let engine = AVAudioEngine()
    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)
    guard format.channelCount > 0, format.sampleRate > 0 else { throw AudioCaptureError.invalidFormat }
    // A tap that drops the buffers: the microphone runs, so iOS keeps the app
    // alive in the background until the night starts (SleepGuard's warm-up).
    input.installTap(onBus: 0, bufferSize: 4096, format: format) { @Sendable _, _ in }
    try engine.start()
    warmEngine = engine
  }

  func coolDown() {
    stopWarmEngine()
    guard !isListening else { return }
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  func start(rawAudioFileName: String?) throws -> AsyncStream<CaptureEvent> {
    stop()
    stopWarmEngine()
    discardClip() // left open by the last night
    self.rawAudioFileName = rawAudioFileName
    try activateSession()
    let (stream, continuation) = AsyncStream.makeStream(of: CaptureEvent.self)
    self.continuation = continuation
    do {
      try startEngine()
    } catch {
      stop()
      throw error
    }
    observeSession()
    Self.logThermalState()
    return stream
  }

  func startClip(id: UUID) throws {
    guard let format, isListening else { throw AudioCaptureError.notListening }
    discardClip()
    let url = clipsDirectory.appendingPathComponent("\(id.uuidString).caf")
    try processor.writeClip(to: AVAudioFile(forWriting: url, settings: format.settings))
    clipURL = url
  }

  func closeClip() -> String? {
    guard let url = clipURL else { return nil }
    processor.closeClip()
    clipURL = nil
    return url.lastPathComponent
  }

  func compressClip(named name: String) async -> String {
    let raw = clipsDirectory.appendingPathComponent(name)
    let compressed = raw.deletingPathExtension().appendingPathExtension("m4a")
    guard await ClipCompressor.compress(from: raw, to: compressed) else {
      // The raw clip still plays; keep it rather than lose the event's audio.
      Log.audio.error("Clip compression failed; keeping the raw clip")
      return name
    }
    try? FileManager.default.removeItem(at: raw)
    return compressed.lastPathComponent
  }

  func discardClip() {
    guard let url = clipURL else { return }
    processor.closeClip()
    clipURL = nil
    try? FileManager.default.removeItem(at: url)
  }

  func pause() {
    guard isListening, !isPaused else { return }
    isPaused = true
    stopEngine()
  }

  func resume() {
    guard isPaused else { return }
    isPaused = false
    resumeIfNeeded()
  }

  func stop() {
    guard isListening else { return }
    isPaused = false
    isInterrupted = false
    // An open clip stays open for the final flush; it gets no more buffers.
    stopEngine()
    observers.forEach(NotificationCenter.default.removeObserver)
    observers = []
    processor.closeRaw()
    rawAudioFileName = nil
    continuation?.finish()
    continuation = nil
    format = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  // MARK: - Engine

  private func activateSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP, .mixWithOthers])
    try session.setActive(true)
    #if !targetEnvironment(simulator)
    guard !session.currentRoute.inputs.isEmpty else { throw AudioCaptureError.noMicrophone }
    #endif
  }

  private func startEngine() throws {
    let engine = AVAudioEngine()
    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)
    guard format.channelCount > 0, format.sampleRate > 0 else { throw AudioCaptureError.invalidFormat }

    processor.begin(format: format, computesSpectrum: rawAudioFileName != nil)
    let processor = processor
    let continuation = continuation
    input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(CaptureProcessor.transformSize), format: format) { @Sendable buffer, _ in
      continuation?.yield(.sample(processor.process(buffer, at: Date())))
    }
    do {
      try engine.start()
    } catch {
      input.removeTap(onBus: 0)
      processor.end()
      throw error
    }
    self.engine = engine
    if let current = self.format, current != format {
      // The open clip and the raw file were made for the old format; their
      // writes would fail.
      Log.audio.notice("Input format changed; the open clip and raw audio end here")
      processor.closeClip()
      processor.closeRaw()
    } else if self.format == nil, let rawAudioFileName {
      openRawAudio(named: rawAudioFileName, format: format)
    }
    self.format = format
  }

  /// The night's full audio, kept for re-processing. A failure loses only
  /// the raw file, never the night.
  private func openRawAudio(named name: String, format: AVAudioFormat) {
    do {
      try processor.writeRaw(to: AVAudioFile(forWriting: clipsDirectory.appendingPathComponent(name), settings: format.settings))
    } catch {
      Log.audio.error("Raw audio not kept: \(error.localizedDescription, privacy: .public)")
    }
  }

  private func stopWarmEngine() {
    guard let warmEngine else { return }
    warmEngine.stop()
    warmEngine.inputNode.removeTap(onBus: 0)
    self.warmEngine = nil
  }

  private func stopEngine() {
    guard let engine else { return }
    engine.stop()
    engine.inputNode.removeTap(onBus: 0)
    self.engine = nil
    processor.end()
  }

  /// Back to listening after an interruption or a route change, when the
  /// engine isn't running.
  private func resumeIfNeeded() {
    guard isListening, !isPaused, !isRunning else { return }
    stopEngine()
    do {
      try activateSession()
      try startEngine()
      Log.audio.info("Listening resumed")
      if isInterrupted {
        isInterrupted = false
        continuation?.yield(.resumed(at: Date()))
      }
    } catch {
      Log.audio.error("Couldn't resume listening: \(error.localizedDescription, privacy: .public)")
    }
  }

  /// The system took the microphone: stop, and say so once.
  private func interruptionBegan() {
    let wasListening = isRunning
    stopEngine()
    guard isListening, !isPaused, wasListening, !isInterrupted else { return }
    isInterrupted = true
    Log.audio.notice("Listening interrupted")
    continuation?.yield(.interrupted(at: Date()))
  }

  /// Logged at the start and on every change: a hot phone throttles, and a
  /// night's log should show it. Nothing changes behaviour on it (yet).
  private nonisolated static func logThermalState() {
    let state = ProcessInfo.processInfo.thermalState
    Log.audio.notice("Thermal state: \(String(describing: state.rawValue), privacy: .public)")
  }

  // MARK: - Session events

  private func observeSession() {
    let center = NotificationCenter.default
    observers = [
      center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
        let began = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) == AVAudioSession.InterruptionType.began.rawValue
        let options = AVAudioSession.InterruptionOptions(rawValue: note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0)
        MainActor.assumeIsolated {
          if began {
            self?.interruptionBegan()
          } else {
            // Tried even without `.shouldResume`: a recording app has no
            // reason to wait for the person, and a failure is retried at the
            // next route, configuration or media-services event.
            if !options.contains(.shouldResume) { Log.audio.notice("Interruption ended without shouldResume; resuming") }
            self?.resumeIfNeeded()
          }
        }
      },
      center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated { self?.resumeIfNeeded() }
      },
      center.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { _ in
        Self.logThermalState()
      },
      // The engine stops itself when its hardware configuration changes.
      center.addObserver(forName: .AVAudioEngineConfigurationChange, object: nil, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated { self?.resumeIfNeeded() }
      },
      center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
        let reason = AVAudioSession.RouteChangeReason(rawValue: note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt ?? 0)
        guard reason == .newDeviceAvailable || reason == .oldDeviceUnavailable else { return }
        MainActor.assumeIsolated { self?.resumeIfNeeded() }
      },
    ]
  }
}
