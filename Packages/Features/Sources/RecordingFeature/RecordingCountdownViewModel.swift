import Foundation
import Observation
import SleepCore

/// The start delay: seconds left until `target` (SleepCore's
/// `RecordingDelay`). At zero, or on Start now, the night starts; Cancel goes
/// back to the prestart.
@MainActor
@Observable
public final class RecordingCountdownViewModel {
  public private(set) var seconds: Int
  private let target: Date
  let routes: RecordingCountdownRoutes
  private var started = false

  public init(target: Date, routes: RecordingCountdownRoutes, now: Date = Date()) {
    self.target = target
    self.routes = routes
    seconds = RecordingDelay.secondsLeft(until: target, now: now)
  }

  /// Counts down; at zero starts the night (once) and returns `true`.
  public func tick(now: Date = Date()) -> Bool {
    seconds = RecordingDelay.secondsLeft(until: target, now: now)
    guard seconds == 0 else { return false }
    startNow()
    return true
  }

  public func startNow() {
    guard !started else { return }
    started = true
    routes.start()
  }

  public func cancel() {
    routes.cancel()
  }
}
