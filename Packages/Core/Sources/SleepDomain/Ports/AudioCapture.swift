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

/// What the capture stream carries: buffers, and the moments the system took
/// the microphone away (a call, another app's audio) and gave it back.
public enum CaptureEvent: Sendable, Equatable {
  /// One analysed buffer.
  case sample(CaptureSample)
  /// Listening stopped without being asked to (not `pause`).
  case interrupted(at: Date)
  /// Listening is back after `interrupted`.
  case resumed(at: Date)
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
public protocol AudioCapture: AnyObject, Sendable {
  /// Asks for microphone access. `true` when granted.
  func requestPermission() async -> Bool
  /// Keeps the audio session and the microphone running without listening,
  /// during the start delay, so the app stays alive in the background until
  /// the night starts. `start` or `coolDown` ends it.
  func warmUp() throws
  /// Ends a warm-up that didn't become a night.
  func coolDown()
  /// Starts listening. One sample per buffer, in order, at whatever rate the
  /// hardware delivers (the session decimates to 20 Hz), until `stop` ends
  /// the stream. An interruption (a call) sends `interrupted`, then
  /// `resumed` when listening comes back on its own; a route change only
  /// pauses the samples briefly. With `rawAudioFileName`, every buffer is also
  /// written to that file in the clips folder (`RawRecording`), and the
  /// spectral score is computed (it is only logged; otherwise it is 0).
  func start(rawAudioFileName: String?) throws -> AsyncStream<CaptureEvent>
  /// Writes the microphone into the clip for event `id` until `closeClip`
  /// or `discardClip`. A clip still open is discarded first.
  func startClip(id: UUID) throws
  /// Stops writing the open clip and keeps it. Returns its file name in the
  /// clips folder (raw audio), or `nil` when no clip was open. Immediate, so
  /// clips close in event order.
  func closeClip() -> String?
  /// Compresses a closed clip. Returns the compressed file's name, or `name`
  /// itself when compression failed (the raw clip still plays). Takes a
  /// moment: run it off the detection path.
  func compressClip(named name: String) async -> String
  /// Closes the open clip and deletes it.
  func discardClip()
  /// Stops listening for a while, keeping the stream and any open files: no
  /// samples until `resume`. The Snore Interrupter pauses the microphone while
  /// its melody plays, so the app doesn't hear itself.
  func pause()
  /// Listening again after `pause`.
  func resume()
  /// Stops listening and ends the sample stream. A clip still open stays open
  /// (nothing more is written to it) for `closeClip` or `discardClip`: the
  /// last event of the night is finalized after the microphone stops.
  func stop()
}

public extension AudioCapture {
  /// Starts listening without keeping the raw audio.
  func start() throws -> AsyncStream<CaptureEvent> {
    try start(rawAudioFileName: nil)
  }
}
