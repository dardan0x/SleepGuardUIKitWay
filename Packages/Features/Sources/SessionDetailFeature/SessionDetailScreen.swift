import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// One night: loads it and hosts the shared `NightDetailContent` (score,
/// stats, sleep stages when there are any, timeline, events with a filter; SleepCore's `EventFilter` and
/// `EventListRow`). The title and the delete button belong to the navigation
/// bar, owned by the shell.
public struct SessionDetailScreen: View {
  let dependencies: SessionDetailDependencies
  let routes: SessionDetailRoutes
  @State private var viewState: ViewState = .loading
  @State private var filter = EventFilter.all

  public init(dependencies: SessionDetailDependencies, routes: SessionDetailRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public var body: some View {
    Group {
      switch viewState {
      case .loading:
        SessionDetailLoadingView()
      case let .loaded(detail):
        let night = detail.session
        ScrollView {
          NightDetailContent(
            night: night, summary: detail.summary, filters: EventFilter.options(for: night.events), filter: $filter,
            onPlay: { row in routes.playEvents(row.playback(in: night.events), row.id) },
            onShowAll: { rows in routes.showAllEvents(rows, night.events) },
            onShare: { row in
              if let event = night.events.first(where: { $0.id == row.id }), event.clipFileName != nil {
                routes.shareEvent(event)
              }
            },
            stages: {
              if let stages = SleepStageBreakdown(segments: night.sleepStages) {
                SleepStagesCard(breakdown: stages, start: night.start, duration: night.duration) {
                  routes.showStagesInfo(stages)
                }
              }
            },
            footer: { EmptyView() })
        }
      case .error:
        SessionDetailErrorView { viewState = .loading }
      }
    }
    // Runs again after "Try again" puts the screen back into `.loading`.
    .task(id: viewState.isLoading) {
      guard viewState.isLoading else { return }
      do {
        let detail = try await dependencies.loadDetail(dependencies.nightID)
        viewState = .loaded(detail)
      } catch {
        if !Task.isCancelled { viewState = .error }
      }
    }
  }

  enum ViewState {
    case loading
    case loaded(SessionDetail)
    case error

    var isLoading: Bool {
      if case .loading = self { true } else { false }
    }
  }
}
