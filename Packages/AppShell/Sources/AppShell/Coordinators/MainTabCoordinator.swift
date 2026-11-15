import FactoryKit
import ScreenKit
import SleepGuardDesignKit
import UIKit

/// One tab's flow: it owns that tab's navigation.
protocol TabFlow: AnyObject {
  var tab: AppTab { get }
  func start()
}

/// The tab bar. Builds one flow per tab in the brand's `tabs`, in that order.
/// Tabs without their feature yet get a placeholder flow (F8).
final class MainTabCoordinator {
  let tabBarController = UITabBarController()
  private(set) var flows: [any TabFlow] = []

  /// `onStartRecording`: the recording flow is the app coordinator's, not a tab's.
  init(container: Container, onStartRecording: @escaping @MainActor () -> Void = {}) {
    let theme = container.theme()
    let composer = PlaceholderScreenComposer(theme: theme)

    let navigationControllers = container.brand().configuration.tabs.map { tab in
      let navigator = NavigationControllerNavigator()
      let navigation = navigator.navigationController
      navigation.tabBarItem = UITabBarItem(title: tab.title, image: UIImage(systemName: tab.iconName), selectedImage: nil)
      navigation.navigationBar.prefersLargeTitles = true
      Appearance.apply(theme, to: navigation.navigationBar)

      let flow: any TabFlow = switch tab {
      case .history: HistoryFlow(navigator: navigator, container: container)
      case .statistics: StatisticsFlow(navigator: navigator, container: container, onStartRecording: onStartRecording)
      case .settings, .learn: PlaceholderFlow(tab: tab, navigator: navigator, composer: composer)
      }
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
