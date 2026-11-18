import Foundation
import Observation
import SleepCore

public struct BriefingRoutes {
  /// A survey answer; the sheet then closes.
  public var answer: @MainActor (LifestyleChip) -> Void
  public var close: @MainActor () -> Void

  public init(answer: @escaping @MainActor (LifestyleChip) -> Void, close: @escaping @MainActor () -> Void) {
    self.answer = answer
    self.close = close
  }
}

/// The morning briefing: what to show, and the survey answer or Close.
@MainActor
@Observable
public final class BriefingViewModel {
  public let briefing: Briefing
  let routes: BriefingRoutes

  public init(briefing: Briefing, routes: BriefingRoutes) {
    self.briefing = briefing
    self.routes = routes
  }

  public func answer(_ chip: LifestyleChip) {
    routes.answer(chip)
  }

  public func close() {
    routes.close()
  }
}
