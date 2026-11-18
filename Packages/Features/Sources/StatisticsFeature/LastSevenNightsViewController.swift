import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

/// The last 7 recorded days in the shared `LastSevenNightsContent`; the
/// numbers are SleepCore's `NightDayStats` and `ScoreTrend`.
public final class LastSevenNightsViewController: NightsScreenController {
  let routes: NightListRoutes

  public init(dependencies: StatisticsDependencies, routes: NightListRoutes, theme: Theme, chrome: ScreenChrome) {
    self.routes = routes
    super.init(dependencies: dependencies, theme: theme, chrome: chrome)
  }

  override func render() {
    guard let nights else { return }
    let (stats, trend, open) = (NightDayStats.recent(from: nights), ScoreTrend.weekOverWeek(nights), routes.openNight)
    list.rows = [.init(id: "last-seven", configuration: hosted {
      LastSevenNightsContent(stats: stats, trend: trend, onOpen: open)
    })]
  }
}
