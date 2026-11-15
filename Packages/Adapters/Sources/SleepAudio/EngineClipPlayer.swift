import AVFoundation
import SleepCore
import SleepDomain

/// `ClipPlayer` over AVAudioEngine: player → 2-band EQ → mixer. With enhanced
/// audio on, the EQ band-passes (`PlaybackEnhancement`) and boosts the clip's
/// peak (`PlaybackGain`); off, it is bypassed and playback is bit-exact. The
/// saved files are never changed. Same chain as SleepGuard's controller.
@MainActor
final class EngineClipPlayer: ClipPlayer {
  var onInterruption: (@MainActor () -> Void)?
  var isEnhanced = true {
    didSet {
      guard oldValue != isEnhanced else { return }
      applyEnhancement()
    }
  }

  private let engine = AVAudioEngine()
  private let node = AVAudioPlayerNode()
  private let eq = AVAudioUnitEQ(numberOfBands: 2)
  private var connectedFormat: AVAudioFormat?
  private var file: AVAudioFile?
  /// Boost for the loaded file, used while enhanced.
  private(set) var boostDB: Float = 0
  private var interruptionObserver: NSObjectProtocol?

  // Position: from when playback started, or where it paused.
  private(set) var isPlaying = false
  private var startedAt: TimeInterval = 0
  private var startOffset: TimeInterval = 0
  private var endOffset: TimeInterval = 0
  private var pausedPosition: TimeInterval = 0
  /// Discards completions of segments that were paused, stopped or replaced.
  private var token = 0

  init() {
    engine.attach(node)
    engine.attach(eq)
    let highPass = eq.bands[0]
    highPass.filterType = .highPass
    highPass.frequency = PlaybackEnhancement.highPassHz
    highPass.bandwidth = 1
    highPass.gain = 0
    let lowPass = eq.bands[1]
    lowPass.filterType = .lowPass
    lowPass.frequency = PlaybackEnhancement.lowPassHz
    lowPass.bandwidth = 1
    lowPass.gain = 0
    applyEnhancement()
  }

  var position: TimeInterval {
    guard isPlaying else { return pausedPosition }
    return min(startOffset + (ProcessInfo.processInfo.systemUptime - startedAt), endOffset)
  }

  func load(_ url: URL) throws -> TimeInterval {
    invalidatePlayback()
    file = nil
    let file = try AVAudioFile(forReading: url)
    try connect(format: file.processingFormat)
    self.file = file
    pausedPosition = 0
    boostDB = Self.peak(of: file).map { PlaybackGain.boostDB(peak: $0) } ?? 0
    applyEnhancement()
    observeInterruptions()
    return TimeInterval(file.length) / file.processingFormat.sampleRate
  }

  func play(from offset: TimeInterval, for duration: TimeInterval, onFinish: @escaping @MainActor () -> Void) throws {
    guard let file else { return }
    try activateSession()
    if !engine.isRunning { try engine.start() }

    let rate = file.processingFormat.sampleRate
    let first = AVAudioFramePosition(max(0, offset) * rate)
    let count = min(file.length - first, AVAudioFramePosition(max(0, duration) * rate))
    guard count > 0 else {
      onFinish()
      return
    }
    token &+= 1
    let current = token
    node.stop() // drops anything scheduled before
    // `.dataPlayedBack`: called once heard, not once read, so the end of a
    // clip isn't cut off by what follows.
    node.scheduleSegment(file, startingFrame: first, frameCount: AVAudioFrameCount(count), at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
      Task { @MainActor in
        guard let self, self.token == current else { return }
        self.pausedPosition = self.endOffset
        self.isPlaying = false
        onFinish()
      }
    }
    node.play()
    startOffset = offset
    endOffset = offset + TimeInterval(count) / rate
    startedAt = ProcessInfo.processInfo.systemUptime
    isPlaying = true
  }

  func pause() {
    guard isPlaying else { return }
    pausedPosition = position
    invalidatePlayback()
    node.pause()
  }

  func stop() {
    invalidatePlayback()
    node.stop()
    if engine.isRunning { engine.stop() }
    interruptionObserver.map { NotificationCenter.default.removeObserver($0) }
    interruptionObserver = nil
    file = nil
    pausedPosition = 0
  }

  // MARK: - Private

  private func invalidatePlayback() {
    token &+= 1
    isPlaying = false
  }

  /// Bypass off: band-pass plus the file's boost. On: untouched.
  private func applyEnhancement() {
    let bypass = !isEnhanced
    eq.bands[0].bypass = bypass
    eq.bands[1].bypass = bypass
    eq.bypass = bypass
    eq.globalGain = bypass ? 0 : boostDB
  }

  /// Reconnects only when the format changes (sample rate, channels, layout).
  private func connect(format: AVAudioFormat) throws {
    if let connected = connectedFormat,
       connected.sampleRate == format.sampleRate,
       connected.channelCount == format.channelCount,
       connected.commonFormat == format.commonFormat
    {
      return
    }
    if engine.isRunning { engine.stop() }
    engine.disconnectNodeInput(eq)
    engine.disconnectNodeInput(engine.mainMixerNode)
    engine.connect(node, to: eq, format: format)
    engine.connect(eq, to: engine.mainMixerNode, format: format)
    connectedFormat = format
  }

  private func activateSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .default)
    try session.setActive(true)
  }

  private func observeInterruptions() {
    guard interruptionObserver == nil else { return }
    interruptionObserver = NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification, object: nil, queue: .main)
    { [weak self] _ in
      Task { @MainActor in
        guard let self, self.isPlaying else { return }
        self.pausedPosition = self.position
        self.invalidatePlayback()
        self.onInterruption?()
      }
    }
  }

  /// The loudest sample of the file, 0...1; `nil` when it can't be read.
  /// Leaves the file's read position where it was.
  static func peak(of file: AVAudioFile) -> Float? {
    let length = AVAudioFrameCount(file.length)
    guard length > 0, let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: length) else { return nil }
    let saved = file.framePosition
    defer { file.framePosition = saved }
    file.framePosition = 0
    guard (try? file.read(into: buffer)) != nil, let channels = buffer.floatChannelData else { return nil }
    var peak: Float = 0
    for channel in 0..<Int(buffer.format.channelCount) {
      let samples = UnsafeBufferPointer(start: channels[channel], count: Int(buffer.frameLength))
      peak = max(peak, samples.map(abs).max() ?? 0)
    }
    return peak
  }
}
