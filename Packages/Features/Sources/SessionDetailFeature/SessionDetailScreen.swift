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
  /// "Show all": the full event list (a sheet, F3-T4).
  public var showAllEvents: @MainActor () -> Void

  public init(showAllEvents: @escaping @MainActor () -> Void) {
    self.showAllEvents = showAllEvents
  }
}

/// One night: score, stats, and its events with a category filter. The title
/// and the delete button belong to the navigation bar, owned by the shell.
public struct SessionDetailScreen: View {
  private let dependencies: SessionDetailDependencies
  private let routes: SessionDetailRoutes
  @State private var viewState: ViewState = .loading
  @Environment(\.theme) private var theme

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
        SessionDetailLoadedView(detail: detail, onShowAll: routes.showAllEvents)
      case .error:
        SessionDetailErrorView { viewState = .loading }
      }
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
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
