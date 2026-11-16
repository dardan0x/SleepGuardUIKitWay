import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// For screens that list nights (Last 7 Nights, Calendar).
public struct NightListRoutes {
  /// A day's first night.
  public var openNight: @MainActor (NightSummary) -> Void

  public init(openNight: @escaping @MainActor (NightSummary) -> Void) {
    self.openNight = openNight
  }
}

/// The last 7 recorded days. Loads the nights live and hosts the shared
/// `LastSevenNightsContent`; the numbers are SleepCore's `NightDayStats` and
/// `ScoreTrend`.
public struct LastSevenNightsScreen: View {
  let dependencies: StatisticsDependencies
  let routes: NightListRoutes
  @State private var state: NightsState = .loading

  public init(dependencies: StatisticsDependencies, routes: NightListRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public var body: some View {
    Group {
      switch state {
      case .loading:
        StatisticsLoadingContent()
      case let .loaded(nights):
        ScrollView {
          LastSevenNightsContent(
            stats: NightDayStats.recent(from: nights), trend: ScoreTrend.weekOverWeek(nights), onOpen: routes.openNight)
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
