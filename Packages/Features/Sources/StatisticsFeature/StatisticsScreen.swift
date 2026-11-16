import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

public struct StatisticsDependencies: Sendable {
  public var nights: any SessionRepository

  public init(nights: any SessionRepository) {
    self.nights = nights
  }
}

public struct StatisticsRoutes {
  public var startRecording: @MainActor () -> Void
  /// "View month": Trends.
  public var showTrends: @MainActor () -> Void
  /// "See all" on the 7-night chart.
  public var showLastSevenNights: @MainActor () -> Void

  public init(
    startRecording: @escaping @MainActor () -> Void,
    showTrends: @escaping @MainActor () -> Void,
    showLastSevenNights: @escaping @MainActor () -> Void)
  {
    self.startRecording = startRecording
    self.showTrends = showTrends
    self.showLastSevenNights = showLastSevenNights
  }
}

/// The dashboard: loads the nights live and hosts the shared content
/// (`StatisticsDashboardContent`, same as SleepGuard's). Every number comes
/// from SleepCore's rules; the title and the calendar button belong to the
/// navigation bar (shell).
public struct StatisticsScreen: View {
  let dependencies: StatisticsDependencies
  let routes: StatisticsRoutes
  @State private var viewState: ViewState = .loading

  public init(dependencies: StatisticsDependencies, routes: StatisticsRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public var body: some View {
    Group {
      switch viewState {
      case .loading:
        StatisticsLoadingContent()
      case .empty:
        StatisticsEmptyContent(onStartRecording: routes.startRecording)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      case let .loaded(dashboard, now):
        VStack(spacing: 0) {
          ScrollView {
            StatisticsDashboardContent(
              dashboard: dashboard, latest: dashboard.latest, now: now,
              onShowTrends: routes.showTrends, onShowLastSevenNights: routes.showLastSevenNights)
          }
          StartRecordingButton(height: 56, action: routes.startRecording)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
      }
    }
    .task {
      for await nights in await dependencies.nights.observeSummaries() {
        let now = Date()
        viewState = NightDashboard.make(from: nights, now: now).map { .loaded($0, now: now) } ?? .empty
      }
    }
  }

  enum ViewState {
    case loading
    case empty
    /// `now`: when the dashboard was made, for "last night" and the week strip.
    case loaded(NightDashboard, now: Date)
  }
}
