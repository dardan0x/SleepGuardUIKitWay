import Foundation
import Observation
import SleepCore
import SleepDomain

/// One night's screen: loads it (with sleep stages when available), keeps the
/// event filter, and turns the detail's taps into routes.
@MainActor
@Observable
public final class SessionDetailViewModel {
  public enum State {
    case loading
    case loaded(SessionDetail)
    case error
  }

  public private(set) var state: State = .loading
  public private(set) var filter = EventFilter.all
  let dependencies: SessionDetailDependencies
  let routes: SessionDetailRoutes

  public init(dependencies: SessionDetailDependencies, routes: SessionDetailRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  /// Whether `load()` has anything to do: not yet loaded, not failed.
  public var needsLoading: Bool {
    if case .loading = state { true } else { false }
  }

  /// Loads the night, then adds its sleep stages when there are new ones.
  /// Cancelled (the screen went away), it stays loading, so the next
  /// appearance loads again; it never shows an error for that. Only the load
  /// can fail: the stages are extra.
  public func load() async {
    guard needsLoading else { return }
    let detail: SessionDetail
    do {
      detail = try await dependencies.loadDetail(dependencies.nightID)
    } catch {
      if !Task.isCancelled { state = .error }
      return
    }
    guard !Task.isCancelled else { return }
    state = .loaded(detail)
    if let enriched = await dependencies.enrichDetail(detail.session), !Task.isCancelled {
      state = .loaded(enriched)
    }
  }

  /// "Try again": back to loading; the screen calls `load()`.
  public func retry() {
    state = .loading
  }

  public func select(_ filter: EventFilter) {
    self.filter = filter
  }

  public func play(_ row: EventListRow) {
    guard let night else { return }
    routes.playEvents(row.playback(in: night.events), row.id)
  }

  public func showAll(_ rows: [EventListRow]) {
    guard let night else { return }
    routes.showAllEvents(rows, night.events)
  }

  /// Only an event with a clip has something to share.
  public func share(_ row: EventListRow) {
    guard let event = night?.events.first(where: { $0.id == row.id }), event.clipFileName != nil else { return }
    routes.shareEvent(event)
  }

  public func showStagesInfo(_ stages: SleepStageBreakdown) {
    routes.showStagesInfo(stages)
  }

  private var night: Night? {
    if case let .loaded(detail) = state { detail.session } else { nil }
  }
}
