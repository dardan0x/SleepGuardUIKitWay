import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SwiftUI

public struct HistoryDependencies: Sendable {
  /// The nights. A plain read, so the screen holds the port itself.
  public var nights: any SessionRepository
  public var deleteNight: DeleteSession

  public init(nights: any SessionRepository, deleteNight: DeleteSession) {
    self.nights = nights
    self.deleteNight = deleteNight
  }
}

public struct HistoryRoutes {
  public var openNight: @MainActor (Night.ID) -> Void

  public init(openNight: @escaping @MainActor (Night.ID) -> Void) {
    self.openNight = openNight
  }
}

/// Every recorded night, by month and day. Updates live as nights are saved or
/// deleted; re-subscribing when the screen reappears yields the current list
/// at once, so returning from a night never shows the loading state.
public struct HistoryScreen: View {
  private let dependencies: HistoryDependencies
  private let routes: HistoryRoutes
  @State private var viewState: ViewState = .loading
  @State private var pendingDelete: HistoryDay?
  @State private var deleteFailed = false
  @Environment(\.calendar) private var calendar
  @Environment(\.theme) private var theme

  public init(dependencies: HistoryDependencies, routes: HistoryRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public var body: some View {
    Group {
      switch viewState {
      case .loading:
        HistoryLoadingView()
      case .empty:
        HistoryEmptyView()
      case let .loaded(months):
        HistoryLoadedView(months: months, onOpen: routes.openNight, onDelete: { pendingDelete = $0 })
      }
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
    .task {
      for await summaries in await dependencies.nights.observeSummaries() {
        viewState = summaries.isEmpty ? .empty : .loaded(HistorySections.make(from: summaries, calendar: calendar))
      }
    }
    .alert(Strings.recordingsDetailRemoveTitle, isPresented: isConfirmingDelete, presenting: pendingDelete) { day in
      Button(Strings.actionRemove, role: .destructive) { delete(day) }
      Button(Strings.actionDiscard, role: .cancel) {}
    } message: { day in
      Text(String(format: Strings.recordingsDetailRemoveConfirmFormat, day.nights.count))
    }
    .alert(Strings.recordingsErrorTitle, isPresented: $deleteFailed) {}
  }

  private var isConfirmingDelete: Binding<Bool> {
    Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
  }

  /// The list updates itself from the repository once each night is gone.
  private func delete(_ day: HistoryDay) {
    Task {
      do {
        for night in day.nights {
          try await dependencies.deleteNight(night.id)
        }
      } catch {
        if !Task.isCancelled { deleteFailed = true }
      }
    }
  }

  enum ViewState {
    case loading
    case empty
    case loaded([HistoryMonth])
  }
}
