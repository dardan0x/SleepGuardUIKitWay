import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// Trends: the last week's or month's nights, each on its own. Loads the
/// nights live and hosts the shared `TrendsContent`; the numbers are
/// SleepCore's `NightPeriod`, the title is in the navigation bar.
public struct TrendsScreen: View {
  let dependencies: StatisticsDependencies
  @State private var state: NightsState = .loading
  @State private var range = TrendsRange.week

  public init(dependencies: StatisticsDependencies) {
    self.dependencies = dependencies
  }

  public var body: some View {
    Group {
      switch state {
      case .loading:
        StatisticsLoadingContent()
      case let .loaded(nights):
        ScrollView {
          TrendsContent(range: $range, period: NightPeriod(lastDays: range.days, of: nights, now: Date()))
        }
      }
    }
    .task {
      for await nights in await dependencies.nights.observeSummaries() {
        state = .loaded(nights)
      }
    }
  }
}
