import AVFoundation
import SleepCore
import SleepDomain

/// `MelodyRecorder` over AVAudioRecorder: AAC, 44.1 kHz mono, stopped at
/// SleepCore's maximum length (SleepGuard's settings).
@MainActor
final class AVMelodyRecorder: MelodyRecorder {
  private let take = FileManager.default.temporaryDirectory.appendingPathComponent("melody_take.m4a")
  private var recorder: AVAudioRecorder?
  private var limit: Task<Void, Never>?
  private var hasTake = false
  /// The take's length once stopped.
  private var recorded: TimeInterval = 0

  var elapsed: TimeInterval {
    recorder?.currentTime ?? recorded
  }

  func requestPermission() async -> Bool {
    await AVAudioApplication.requestRecordPermission()
  }

  func start(onLimit: @escaping @MainActor () -> Void) throws {
    discard()
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
    try session.setActive(true)
    let recorder = try AVAudioRecorder(url: take, settings: [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44100,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ])
    guard recorder.record(forDuration: CustomMelodies.maxRecordingDuration) else {
      throw AudioCaptureError.noMicrophone
    }
    self.recorder = recorder
    hasTake = true
    limit = Task { [weak self] in
      try? await Task.sleep(for: .seconds(CustomMelodies.maxRecordingDuration))
      guard !Task.isCancelled, let self else { return }
      _ = self.stop()
      onLimit()
    }
  }

  func stop() -> URL? {
    limit?.cancel()
    limit = nil
    if let recorder { recorded = recorder.currentTime }
    recorder?.stop()
    recorder = nil
    return hasTake ? take : nil
  }

  func discard() {
    _ = stop()
    hasTake = false
    recorded = 0
    try? FileManager.default.removeItem(at: take)
  }
}
