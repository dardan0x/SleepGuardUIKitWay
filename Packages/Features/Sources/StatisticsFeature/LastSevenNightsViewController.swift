import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

/// The last 7 recorded days in the shared `LastSevenNightsContent`; the
/// numbers are SleepCore's `NightDayStats` and `ScoreTrend`.
public final class LastSevenNightsViewController: NightsScreenController {
  override public init(viewModel: NightsViewModel, theme: Theme, chrome: ScreenChrome) {
    super.init(viewModel: viewModel, theme: theme, chrome: chrome)
  }

  override func render(_ nights: [NightSummary]) {
    let (stats, trend, viewModel) = (NightDayStats.recent(from: nights), ScoreTrend.weekOverWeek(nights), viewModel)
    list.rows = [.init(id: "last-seven", configuration: hosted {
      LastSevenNightsContent(stats: stats, trend: trend, onOpen: { viewModel.open($0) })
    })]
  }
}
