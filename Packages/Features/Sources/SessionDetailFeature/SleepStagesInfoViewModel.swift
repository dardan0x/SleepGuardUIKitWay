import Foundation
import Observation
import SleepCore

public struct SleepStagesInfoRoutes {
  /// The sheet's own close button.
  public var close: @MainActor () -> Void

  public init(close: @escaping @MainActor () -> Void) {
    self.close = close
  }
}

/// The sleep-stages sheet, from the night detail or the dashboard: the
/// breakdown to explain, and Close.
@MainActor
@Observable
public final class SleepStagesInfoViewModel {
  public let breakdown: SleepStageBreakdown
  let routes: SleepStagesInfoRoutes

  public init(breakdown: SleepStageBreakdown, routes: SleepStagesInfoRoutes) {
    self.breakdown = breakdown
    self.routes = routes
  }

  public func close() {
    routes.close()
  }
}
