import FactoryKit
import ScreenKit
import SleepGuardDesignKit
import StatisticsFeature
import UIKit

/// Builds the Statistics screens: dependencies, then the view model, then the
/// screen (ADR 0008). Wiring only.
struct StatisticsFactory {
  let container: Container

  private var dependencies: StatisticsDependencies {
    let prompt = container.profilePromptCheck()
    return StatisticsDependencies(nights: container.sessionRepository(), asksForProfile: { await prompt.shouldAsk() })
  }

  /// The dashboard, with the calendar button in the bar.
  func makeDashboard(routes: StatisticsRoutes, onCalendar: @escaping @MainActor () -> Void) -> UIViewController {
    StatisticsViewController(
      viewModel: StatisticsViewModel(dependencies: dependencies, routes: routes), theme: container.theme(),
      chrome: ScreenChrome(
        title: Strings.tabStatistics, largeTitle: true,
        trailingItems: [BarItem(systemImage: "calendar", accessibilityLabel: Strings.watchCalendar, action: onCalendar)]))
  }

  func makeTrends() -> UIViewController {
    TrendsViewController(
      viewModel: NightsViewModel(dependencies: dependencies), theme: container.theme(),
      chrome: ScreenChrome(title: Strings.statsTrendsTitle))
  }

  func makeLastSevenNights(routes: NightListRoutes) -> UIViewController {
    LastSevenNightsViewController(
      viewModel: NightsViewModel(dependencies: dependencies, routes: routes), theme: container.theme(),
      chrome: ScreenChrome(title: Strings.statsTrendsLastSevenNights))
  }

  func makeCalendar(routes: NightListRoutes) -> UIViewController {
    CalendarViewController(
      viewModel: NightsViewModel(dependencies: dependencies, routes: routes), theme: container.theme(),
      chrome: ScreenChrome(title: Strings.watchCalendar))
  }
}
