import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SwiftUI

/// Trends: the last week's or month's nights, each on its own. Every number
/// comes from SleepCore's `NightPeriod`; the title is in the navigation bar.
public struct TrendsScreen: View {
  let dependencies: StatisticsDependencies
  @State private var state: NightsState = .loading

  public init(dependencies: StatisticsDependencies) {
    self.dependencies = dependencies
  }

  public var body: some View {
    Group {
      switch state {
      case .loading:
        StatisticsLoadingView()
      case let .loaded(nights):
        ScrollView {
          TrendsContent(nights: nights, now: Date())
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
