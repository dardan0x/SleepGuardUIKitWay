import Foundation
import Observation
import SleepCore

/// The night just recorded: its summary, then Save or Discard. A night under
/// `Night.minimumSaveDuration` can't be saved, as in SleepGuard.
@MainActor
@Observable
public final class SessionSummaryViewModel {
  public enum Alert: Equatable {
    case tooShort
  }

  public let night: Night
  public let summary: NightSummary
  public private(set) var alert: Alert?
  let routes: SessionSummaryRoutes

  public init(night: Night, scoreConfig: SleepScoreConfig = .default, routes: SessionSummaryRoutes) {
    self.night = night
    summary = night.summary(using: scoreConfig)
    self.routes = routes
  }

  public func save() {
    guard night.duration >= Night.minimumSaveDuration else {
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
