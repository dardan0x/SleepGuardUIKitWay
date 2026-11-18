import Foundation
import Observation
import SleepCore
import SleepDomain

/// For a statistics screen over every night (Trends, Calendar, Last 7
/// Nights): the nights live from the repository, opening a day's night, and
/// the calendar's month and selected day.
@MainActor
@Observable
public final class NightsViewModel {
  /// `nil` until the first list arrives. No empty state: the numbers read 0.
  public private(set) var nights: [NightSummary]?
  public private(set) var month: Date
  public private(set) var selectedDay: Date
  let dependencies: StatisticsDependencies
  let routes: NightListRoutes?
  private let calendar: Calendar
  private let now: @MainActor () -> Date

  public init(
    dependencies: StatisticsDependencies, routes: NightListRoutes? = nil, calendar: Calendar = .current,
    now: @escaping @MainActor () -> Date = Date.init)
  {
    self.dependencies = dependencies
    self.routes = routes
    self.calendar = calendar
    self.now = now
    month = now()
    selectedDay = calendar.startOfDay(for: now())
  }

  /// Follows the nights until cancelled.
  public func observe() async {
    for await nights in await dependencies.nights.observeSummaries() {
      self.nights = nights
    }
  }

  public func open(_ night: NightSummary) {
    routes?.openNight(night)
  }

  public func setMonth(_ month: Date) {
    self.month = month
  }

  public func select(_ day: Date) {
    selectedDay = day
  }

  /// "Today": this month, today selected.
  public func goToToday() {
    month = now()
    selectedDay = calendar.startOfDay(for: now())
  }
}
