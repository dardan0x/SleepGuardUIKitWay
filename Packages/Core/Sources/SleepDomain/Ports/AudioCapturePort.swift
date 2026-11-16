import Foundation

/// One analysed microphone buffer: the inputs the detection rules take.
public struct CaptureSample: Sendable, Equatable {
  /// When the buffer was taken.
  public let time: Date
  /// RMS level of the buffer, dBFS (SleepCore's `AudioLevels`).
  public let db: Float
  /// Peak level of the buffer, dBFS: tracks impulsive snoring better than RMS.
  public let peakDB: Float
  /// SleepCore's spectral snore score of the buffer, 0...1.
  public let spectralScore: Float
  /// The sound classifier's latest snore and speech confidences, 0...1
  /// (SleepCore's `SoundClassLabels`). The classifier answers about twice a
  /// second, so consecutive samples repeat them.
  public let snoreConfidence: Float
  public let speechConfidence: Float

  public init(time: Date, db: Float, peakDB: Float, spectralScore: Float, snoreConfidence: Float, speechConfidence: Float) {
    self.time = time
    self.db = db
    self.peakDB = peakDB
    self.spectralScore = spectralScore
    self.snoreConfidence = snoreConfidence
    self.speechConfidence = speechConfidence
  }
}

public enum AudioCaptureError: Error, Equatable {
  /// The device has no microphone input right now.
  case noMicrophone
  /// The input reports no channels or no sample rate.
  case invalidFormat
  /// A clip was asked for while not listening.
  case notListening
}

/// Listens to the microphone through the night and writes the clip of each
/// event. Implemented by `SleepAudio` over AVAudioEngine; the recording actor
/// (F7-T4) turns its samples into detection messages.
///
/// Main-actor: it owns the audio session and engine. The samples come out as
/// a stream, so the consumer can be on any actor.
@MainActor
public protocol AudioCapturePort: AnyObject, Sendable {
  /// Asks for microphone access. `true` when granted.
  func requestPermission() async -> Bool
  /// Starts listening. One sample per buffer, in order, until `stop` ends
  /// the stream. An interruption (a call) or a route change pauses the
  /// samples; listening resumes on its own when the system allows.
  func start() throws -> AsyncStream<CaptureSample>
  /// Writes the microphone into the clip for event `id` until `finishClip`
  /// or `discardClip`. An unfinished clip is discarded first.
  func startClip(id: UUID) throws
  /// Closes the open clip and compresses it. Returns its file name in the
  /// clips folder, or `nil` when no clip was open.
  func finishClip() async -> String?
  /// Closes the open clip and deletes it.
  func discardClip()
  /// Stops listening, ends the sample stream and discards an unfinished clip.
  func stop()
}
