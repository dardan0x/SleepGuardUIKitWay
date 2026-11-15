import Foundation

/// Plays one audio clip at a time. Implemented by `SleepAudio` over
/// AVAudioEngine; a state owner decides what plays (SleepCore's `ClipPlaylist`).
/// Main-actor: it drives what the user hears from a screen.
@MainActor
public protocol ClipPlayer: AnyObject {
  /// Opens the file. Returns its length in seconds.
  func load(_ url: URL) throws -> TimeInterval
  /// Plays the loaded file from `offset` for `duration` seconds. `onFinish`
  /// runs once that has been heard to the end, never after `pause` or `stop`.
  func play(from offset: TimeInterval, for duration: TimeInterval, onFinish: @escaping @MainActor () -> Void) throws
  /// Stops where it is; `position` keeps that place.
  func pause()
  /// Seconds into the loaded file.
  var position: TimeInterval { get }
  /// Band-pass and peak boost (`PlaybackEnhancement`, `PlaybackGain`) on or off.
  var isEnhanced: Bool { get set }
  /// Called when the system interrupts playback (a call, another app).
  var onInterruption: (@MainActor () -> Void)? { get set }
  /// Releases the audio engine and the file.
  func stop()
}
