import Foundation
import Observation
import SleepCore
import SleepDomain

/// The History screen's state and intents: every night by month and day,
/// live from the repository; confirming and performing a day's delete.
@MainActor
@Observable
public final class HistoryViewModel {
  public enum State: Equatable {
    case loading
    case empty
    case loaded([NightMonth])
  }

  public enum Alert: Equatable {
    /// "Remove these recordings?" for a day's nights.
    case confirmDelete(NightDay)
    case deleteFailed
  }

  public private(set) var state: State = .loading
  public private(set) var alert: Alert?
  let dependencies: HistoryDependencies
  let routes: HistoryRoutes
  private let calendar: Calendar

  public init(dependencies: HistoryDependencies, routes: HistoryRoutes, calendar: Calendar = .autoupdatingCurrent) {
    self.dependencies = dependencies
    self.routes = routes
    self.calendar = calendar
  }

  /// Follows the nights until cancelled. Re-subscribing yields the current
  /// list at once, so coming back never shows the loading state.
  public func observe() async {
    for await summaries in await dependencies.nights.observeSummaries() {
      show(summaries)
    }
  }

  func show(_ summaries: [NightSummary]) {
    state = summaries.isEmpty ? .empty : .loaded(NightMonth.months(from: summaries, calendar: calendar))
  }

  public func open(_ night: NightSummary) {
    routes.openNight(night)
  }

  public func askToDelete(_ day: NightDay) {
    alert = .confirmDelete(day)
  }

  public func dismissAlert() {
    alert = nil
  }

  /// Deletes every night of the confirmed day in one write (all or none);
  /// the list updates itself from the repository. A failure leaves the whole
  /// day and says so.
  public func confirmDelete() async {
    guard case let .confirmDelete(day) = alert else { return }
    alert = nil
    do {
      try await dependencies.deleteNights(day.nights.map(\.id))
    } catch {
      if !Task.isCancelled { alert = .deleteFailed }
    }
  }
}
