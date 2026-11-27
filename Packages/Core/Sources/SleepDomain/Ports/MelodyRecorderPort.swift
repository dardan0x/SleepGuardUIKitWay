import Foundation

/// Records a sound of one's own, up to `CustomMelodies.maxRecordingDuration`.
/// Implemented by `SleepAudioAdapter`.
@MainActor
public protocol MelodyRecorderPort: AnyObject, Sendable {
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
