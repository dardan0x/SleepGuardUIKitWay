import Foundation
import Observation
import SleepCore

/// The night just recorded: its summary, then Save or Discard. A night
/// shorter than the `SaveRules` minimum can't be saved, as in SleepGuard.
@MainActor
@Observable
public final class SessionSummaryViewModel {
  public enum Alert: Equatable {
    case tooShort
  }

  public let night: Night
  public let summary: NightSummary
  public private(set) var alert: Alert?
  public let saveRules: SaveRules
  let routes: SessionSummaryRoutes

  public init(
    night: Night,
    scoreConfig: SleepScoreConfig = .default,
    saveRules: SaveRules = .standard,
    routes: SessionSummaryRoutes)
  {
    self.night = night
    self.saveRules = saveRules
    summary = night.summary(using: scoreConfig)
    self.routes = routes
  }

  public func save() {
    guard saveRules.isLongEnough(night.duration) else {
      alert = .tooShort
      return
    }
    routes.save(night)
  }

  public func discard() {
    routes.discard(night)
  }

  public func dismissAlert() {
    alert = nil
  }
}
