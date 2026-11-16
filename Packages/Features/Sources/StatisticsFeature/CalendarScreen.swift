import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// A month of nights. Loads the nights live, keeps the month and the selected
/// day, and hosts the shared `CalendarContent` (SleepCore's `CalendarMonth`).
public struct CalendarScreen: View {
  let dependencies: StatisticsDependencies
  let routes: NightListRoutes
  @State private var state: NightsState = .loading
  @State private var month = Date()
  @State private var selectedDay = Calendar.current.startOfDay(for: Date())

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
          CalendarContent(
            month: $month, selectedDay: $selectedDay, nights: nights,
            onToday: {
              month = Date()
              selectedDay = Calendar.current.startOfDay(for: Date())
            },
            onOpen: routes.openNight)
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
