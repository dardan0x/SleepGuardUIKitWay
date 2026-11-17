import Foundation
import SleepCore

/// Plays the Snore Interrupter's melody. Implemented by `SleepAudio`.
@MainActor
public protocol MelodyPlayer: AnyObject, Sendable {
  /// Starts `url`, looping or cut at `duration` (`nil`: the file's length).
  /// `onFinish` is called once when it ends by itself, never after `stop`.
  /// `false` when it couldn't start.
  func play(_ url: URL, loops: Bool, duration: TimeInterval?, onFinish: @escaping @MainActor () -> Void) -> Bool
  func stop()
}

/// The recordings someone made as their own melody, and where any melody's
/// file is (a built-in's comes from the shared `SleepMelodies`). Implemented
/// by `SleepAudio`.
@MainActor
public protocol MelodyStore: AnyObject, Sendable {
  /// Recordings, oldest first.
  func recordings() -> [Melody]
  func url(for melody: Melody) -> URL?
  /// Keeps the take at `take` (moved) as a new recording named `name`.
  func save(take: URL, name: String) -> Melody?
  /// Removes a recording and its file.
  func delete(_ melody: Melody)
}

/// Records a sound of one's own, up to `CustomMelodies.maxRecordingDuration`.
/// Implemented by `SleepAudio`.
@MainActor
public protocol MelodyRecorder: AnyObject, Sendable {
  func requestPermission() async -> Bool
  /// Starts a new take (an earlier one is discarded). `onLimit` is called if
  /// it reaches the maximum length, already stopped.
  func start(onLimit: @escaping @MainActor () -> Void) throws
  /// Stops recording; the take's file, or `nil` when nothing was recorded.
  func stop() -> URL?
  /// How long the current take has been recording.
  var elapsed: TimeInterval { get }
  /// Deletes the take.
  func discard()
}
