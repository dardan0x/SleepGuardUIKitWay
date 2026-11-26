import ScreenKit
import SleepGuardDesignKit
import UIKit

/// One tab's flow: it owns that tab's navigation.
protocol TabFlow: AnyObject {
  var tab: AppTab { get }
  func start()
}

/// The tab bar. Builds one flow per tab in the brand's `tabs`, in that order.
final class MainTabCoordinator {
  let tabBarController = UITabBarController()
  private(set) var flows: [any TabFlow] = []

  /// `makeFlow` builds a tab's flow over its navigator (`AppComposition`).
  init(theme: Theme, tabs: [AppTab], makeFlow: (AppTab, any Navigator) -> any TabFlow) {
    let navigationControllers = tabs.map { tab in
      let navigator = NavigationControllerNavigator()
      let navigation = navigator.navigationController
      navigation.tabBarItem = UITabBarItem(title: tab.title, image: UIImage(systemName: tab.iconName), selectedImage: nil)
      navigation.navigationBar.prefersLargeTitles = true
      Appearance.apply(theme, to: navigation.navigationBar)

      let flow = makeFlow(tab, navigator)
      flow.start()
      flows.append(flow)
      return navigation
    }

    tabBarController.viewControllers = navigationControllers
    Appearance.apply(theme, to: tabBarController.tabBar)
  }
}

extension AppTab {
  var title: String {
    switch self {
    case .statistics: Strings.tabStatistics
    case .history: Strings.tabSessions
    case .settings: Strings.tabSettings
    case .learn: Strings.tabLearn
    }
  }

  /// The same SF Symbols as SleepGuard's tab bar.
  var iconName: String {
    switch self {
    case .statistics: "chart.bar.fill"
    case .history: "waveform"
    case .settings: "gearshape"
    case .learn: "book.fill"
    }
  }
}
