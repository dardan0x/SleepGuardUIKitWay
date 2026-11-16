import AVFoundation
import SleepDomain

/// `AudioCapturePort` over AVAudioEngine, as SleepGuard's recorder captures:
///
/// - **A direct tap on the input node.** No output path: an earlier graph that
///   routed the input to the mixer also fed the speaker, and a mic that hears
///   the speaker forms a feedback loop.
/// - **`.measurement` mode.** No automatic gain or voice processing, so quiet
///   snoring isn't turned down, and the full band reaches the analysis.
/// - **A new engine at every start.** An engine with a tap can't be restarted
///   reliably, and a new route can change the input format.
///
/// Buffer work happens on the audio thread in `CaptureProcessor`.
@MainActor
final class EngineAudioCapture: AudioCapturePort {
  private let clipsDirectory: URL
  private let processor = CaptureProcessor()
  private var engine: AVAudioEngine?
  private var format: AVAudioFormat?
  private var continuation: AsyncStream<CaptureSample>.Continuation?
  private var clipURL: URL?
  private var observers: [NSObjectProtocol] = []

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

  func start() throws -> AsyncStream<CaptureSample> {
    stop()
    try activateSession()
    let (stream, continuation) = AsyncStream.makeStream(of: CaptureSample.self)
    self.continuation = continuation
    do {
      try startEngine()
    } catch {
      stop()
      throw error
    }
    observeSession()
    return stream
  }

  func startClip(id: UUID) throws {
    guard let format, isListening else { throw AudioCaptureError.notListening }
    discardClip()
    let url = clipsDirectory.appendingPathComponent("\(id.uuidString).caf")
    try processor.writeClip(to: AVAudioFile(forWriting: url, settings: format.settings))
    clipURL = url
  }

  func finishClip() async -> String? {
    guard let raw = clipURL else { return nil }
    processor.closeClip()
    clipURL = nil
    let compressed = raw.deletingPathExtension().appendingPathExtension("m4a")
    guard await ClipCompressor.compress(from: raw, to: compressed) else {
      // The raw clip still plays; keep it rather than lose the event's audio.
      Log.audio.error("Clip compression failed; keeping the raw clip")
      return raw.lastPathComponent
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

  func stop() {
    guard isListening else { return }
    discardClip()
    stopEngine()
    observers.forEach(NotificationCenter.default.removeObserver)
    observers = []
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

    processor.begin(format: format)
    let processor = processor
    let continuation = continuation
    input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(CaptureProcessor.transformSize), format: format) { @Sendable buffer, _ in
      continuation?.yield(processor.process(buffer, at: Date()))
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
      // The open clip was made for the old format; its writes would fail.
      Log.audio.notice("Input format changed; the open clip ends here")
      processor.closeClip()
    }
    self.format = format
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
    guard isListening, !isRunning else { return }
    stopEngine()
    do {
      try activateSession()
      try startEngine()
      Log.audio.info("Listening resumed")
    } catch {
      Log.audio.error("Couldn't resume listening: \(error.localizedDescription, privacy: .public)")
    }
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
            self?.stopEngine()
          } else if options.contains(.shouldResume) {
            self?.resumeIfNeeded()
          }
        }
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
