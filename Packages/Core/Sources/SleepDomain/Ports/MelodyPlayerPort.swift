import Foundation

/// Plays the Snore Interrupter's melody. Implemented by `SleepAudioAdapter`.
@MainActor
public protocol MelodyPlayerPort: AnyObject, Sendable {
  /// Starts `url`, looping or cut at `duration` (`nil`: the file's length).
  /// `onFinish` is called once when it ends by itself, never after `stop`.
  /// `false` when it couldn't start.
  func play(_ url: URL, loops: Bool, duration: TimeInterval?, onFinish: @escaping @MainActor () -> Void) -> Bool
  func stop()
}
