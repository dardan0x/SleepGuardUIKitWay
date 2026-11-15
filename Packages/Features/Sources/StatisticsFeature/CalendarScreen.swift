import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SwiftUI

/// A month of nights: a dot per night in its loudest colour, the month's
/// stats, and the selected day's night. From SleepCore's `CalendarMonth`.
public struct CalendarScreen: View {
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
        StatisticsLoadingView()
      case let .loaded(nights):
        ScrollView {
          CalendarContent(nights: nights, today: Date(), onOpen: routes.openNight)
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
