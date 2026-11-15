import FactoryKit
import ScreenKit
import SleepGuardDesignKit
import StatisticsFeature
import UIKit

/// Builds the Statistics screens. Wiring only: resolve, build the screen, host it.
struct StatisticsComposer {
  let container: Container

  private var dependencies: StatisticsDependencies {
    StatisticsDependencies(nights: container.sessionRepository())
  }

  /// The dashboard, with the calendar button in the bar.
  func makeDashboard(routes: StatisticsRoutes, onCalendar: @escaping @MainActor () -> Void) -> UIViewController {
    HostingScreen(
      rootView: StatisticsScreen(dependencies: dependencies, routes: routes),
      theme: container.theme(),
      chrome: ScreenChrome(
        title: Strings.tabStatistics, largeTitle: true,
        trailingItems: [BarItem(systemImage: "calendar", accessibilityLabel: Strings.watchCalendar, action: onCalendar)]))
  }

  func makeTrends() -> UIViewController {
    HostingScreen(
      rootView: TrendsScreen(dependencies: dependencies), theme: container.theme(),
      chrome: ScreenChrome(title: Strings.statsTrendsTitle))
  }

  func makeLastSevenNights(routes: NightListRoutes) -> UIViewController {
    HostingScreen(
      rootView: LastSevenNightsScreen(dependencies: dependencies, routes: routes), theme: container.theme(),
      chrome: ScreenChrome(title: Strings.statsTrendsLastSevenNights))
  }

  func makeCalendar(routes: NightListRoutes) -> UIViewController {
    HostingScreen(
      rootView: CalendarScreen(dependencies: dependencies, routes: routes), theme: container.theme(),
      chrome: ScreenChrome(title: Strings.watchCalendar))
  }
}
