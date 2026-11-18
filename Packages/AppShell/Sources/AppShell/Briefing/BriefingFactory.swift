import BriefingFeature
import FactoryKit
import ScreenKit
import SleepCore
import UIKit

/// Builds the morning briefing sheet: its view model, then the screen
/// (ADR 0008). No bar: the content draws its own close button.
struct BriefingFactory {
  let container: Container

  func make(briefing: Briefing, routes: BriefingRoutes) -> UIViewController {
    BriefingViewController(
      viewModel: BriefingViewModel(briefing: briefing, routes: routes),
      theme: container.theme(), chrome: ScreenChrome(hidesNavigationBar: true))
  }
}
