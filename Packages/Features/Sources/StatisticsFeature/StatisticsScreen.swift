import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// The dashboard: loads the nights live and hosts the shared content
/// (`StatisticsDashboardContent`, same as SleepGuard's) with the latest
/// night's sleep stages in its slot. Every number comes
/// from SleepCore's rules; the title and the calendar button belong to the
/// navigation bar (shell).
public struct StatisticsScreen: View {
  let dependencies: StatisticsDependencies
  let routes: StatisticsRoutes
  @State private var viewState: ViewState = .loading
  @State private var asksForProfile = false

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
            if asksForProfile {
              ProfilePromptCard(
                onOpen: {
                  asksForProfile = false
                  routes.openProfile()
                },
                onDismiss: {
                  withAnimation { asksForProfile = false }
                  routes.dismissProfilePrompt()
                })
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            StatisticsDashboardContent(
              dashboard: dashboard, latest: dashboard.latest, now: now,
              onShowTrends: routes.showTrends, onShowLastSevenNights: routes.showLastSevenNights)
            {
              LatestNightStages(latest: dashboard.latest, nights: dependencies.nights, onInfo: routes.showStagesInfo)
            }
          }
          StartRecordingButton(height: 56, action: routes.startRecording)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
      }
    }
    .task {
      asksForProfile = await dependencies.asksForProfile()
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
