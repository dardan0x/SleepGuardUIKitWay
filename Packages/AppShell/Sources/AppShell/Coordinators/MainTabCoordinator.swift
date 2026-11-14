import FactoryKit
import ScreenKit
import SleepGuardDesignKit
import UIKit

/// The tab bar. Builds one flow per tab in the brand's `tabs`, in that order.
/// Every tab is a placeholder flow until its feature exists (F3, F4, F8).
final class MainTabCoordinator {
  let tabBarController = UITabBarController()
  private(set) var flows: [PlaceholderFlow] = []

  init(container: Container) {
    let theme = container.theme()
    let composer = PlaceholderScreenComposer(theme: theme)

    let navigationControllers = container.brand().configuration.tabs.map { tab in
      let navigator = NavigationControllerNavigator()
      let navigation = navigator.navigationController
      navigation.tabBarItem = UITabBarItem(title: tab.title, image: UIImage(systemName: tab.iconName), selectedImage: nil)
      navigation.navigationBar.prefersLargeTitles = true
      Appearance.apply(theme, to: navigation.navigationBar)

      let flow = PlaceholderFlow(tab: tab, navigator: navigator, composer: composer)
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
