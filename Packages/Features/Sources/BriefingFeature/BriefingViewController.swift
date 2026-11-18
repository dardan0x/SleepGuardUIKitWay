import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

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
public final class BriefingViewController: ScreenController {
  let briefing: Briefing
  let routes: BriefingRoutes

  public init(briefing: Briefing, routes: BriefingRoutes, theme: Theme, chrome: ScreenChrome = ScreenChrome()) {
    self.briefing = briefing
    self.routes = routes
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    let routes = routes
    render(BriefingContent(briefing: briefing, onChip: { routes.answer($0) }, onClose: { routes.close() }))
  }
}
