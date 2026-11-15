import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SwiftUI

public struct SessionDetailDependencies: Sendable {
  public var nightID: Night.ID
  /// Loads the night, adding sleep stages when available.
  public var loadDetail: LoadSessionDetail

  public init(nightID: Night.ID, loadDetail: LoadSessionDetail) {
    self.nightID = nightID
    self.loadDetail = loadDetail
  }
}

public struct SessionDetailRoutes {
  /// "Show all": every row under the current filter, and the night's events
  /// (the sheet's Play needs them to find an episode's clips).
  public var showAllEvents: @MainActor ([DetailEventRow], [NightEvent]) -> Void
  /// Play: the events to play in order, starting with the given one.
  public var playEvents: @MainActor ([NightEvent], NightEvent.ID) -> Void

  public init(
    showAllEvents: @escaping @MainActor ([DetailEventRow], [NightEvent]) -> Void,
    playEvents: @escaping @MainActor ([NightEvent], NightEvent.ID) -> Void)
  {
    self.showAllEvents = showAllEvents
    self.playEvents = playEvents
  }
}

/// One night: score, stats, and its events with a category filter. The title
/// and the delete button belong to the navigation bar, owned by the shell.
public struct SessionDetailScreen: View {
  let dependencies: SessionDetailDependencies
  let routes: SessionDetailRoutes
  @State private var viewState: ViewState = .loading

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
        SessionDetailLoadedView(detail: detail, routes: routes)
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
