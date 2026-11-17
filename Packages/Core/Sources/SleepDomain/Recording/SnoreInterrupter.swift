import Foundation
import SleepCore

/// One night's Snore Interrupter: plays the chosen melody when detection asks
/// (SleepCore's `.melodyRequested`), with the microphone paused so the app
/// doesn't hear itself, as SleepGuard does. However the melody stops (its
/// length, the file's end, Stop, Mute, the night ending), the microphone comes
/// back and `RecordingSession` is told, which records the gap.
@MainActor
public final class SnoreInterrupter {
  nonisolated public let mode: SnoreInterrupterMode
  /// The melody playing now.
  public private(set) var playing: Melody?
  /// Muted for the rest of this night.
  public private(set) var isMuted = false
  /// Set by `RecordingSession`: the melody stopped at this time, microphone back on.
  var onStopped: (@MainActor (Date) -> Void)?

  private let melodyID: Int
  private let player: any MelodyPlayer
  private let store: any MelodyStore
  private let capture: any AudioCapturePort
  private let now: @MainActor () -> Date

  /// `capture` is the night's microphone (the one the session listens to).
  public init(
    mode: SnoreInterrupterMode, melodyID: Int, player: any MelodyPlayer, store: any MelodyStore,
    capture: any AudioCapturePort, now: @escaping @MainActor () -> Date = { Date() })
  {
    self.mode = mode
    self.melodyID = melodyID
    self.player = player
    self.store = store
    self.capture = capture
    self.now = now
  }

  /// Plays when on, not muted and not already playing. `true` when a melody
  /// started (the microphone is paused).
  func play() -> Bool {
    guard mode.isOn, !isMuted, playing == nil else { return false }
    let melody = Melody.resolve(id: melodyID, custom: store.recordings())
    guard let url = store.url(for: melody) else { return false }
    capture.pause()
    let started = player.play(url, loops: mode.loops, duration: mode.playDuration) { [weak self] in
      self?.ended()
    }
    guard started else {
      capture.resume()
      return false
    }
    playing = melody
    return true
  }

  /// Stops the melody now (Stop, or detection's `.melodyStopRequested`).
  public func stop() {
    guard playing != nil else { return }
    player.stop()
    ended()
  }

  /// Stops it and plays nothing more this night.
  public func mute() {
    isMuted = true
    stop()
  }

  private func ended() {
    guard playing != nil else { return }
    playing = nil
    capture.resume()
    onStopped?(now())
  }
}
