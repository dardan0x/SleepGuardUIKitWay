import SleepCore
import SleepGuardContentKit
import SwiftUI

public struct BriefingRoutes {
  /// A survey answer; the sheet then closes.
  public var answer: @MainActor (LifestyleChip) -> Void
  public var close: @MainActor () -> Void

  public init(answer: @escaping @MainActor (LifestyleChip) -> Void, close: @escaping @MainActor () -> Void) {
    self.answer = answer
    self.close = close
  }
}

/// The morning briefing sheet, hosting the shared `BriefingContent`.
public struct BriefingScreen: View {
  let briefing: Briefing
  let routes: BriefingRoutes

  public init(briefing: Briefing, routes: BriefingRoutes) {
    self.briefing = briefing
    self.routes = routes
  }

  public var body: some View {
    BriefingContent(briefing: briefing, onChip: { routes.answer($0) }, onClose: { routes.close() })
  }
}
