import ScreenKit
import SleepCore
import SleepGuardContentKit
import SwiftUI
import UIKit

/// A month of nights in the shared `CalendarContent` (SleepCore's
/// `CalendarMonth`). Owns the month and the selected day.
public final class CalendarViewController: NightsScreenController {
  let routes: NightListRoutes
  private(set) var month = Date()
  private(set) var selectedDay = Calendar.current.startOfDay(for: Date())

  public init(dependencies: StatisticsDependencies, routes: NightListRoutes, theme: Theme, chrome: ScreenChrome) {
    self.routes = routes
    super.init(dependencies: dependencies, theme: theme, chrome: chrome)
  }

  override func render() {
    guard let nights else { return }
    let month = Binding(get: { [weak self] in self?.month ?? Date() }, set: { [weak self] in self?.setMonth($0) })
    let day = Binding(get: { [weak self] in self?.selectedDay ?? Date() }, set: { [weak self] in self?.select($0) })
    let open = routes.openNight
    list.rows = [.init(id: "calendar", configuration: hosted {
      CalendarContent(
        month: month, selectedDay: day, nights: nights,
        onToday: { [weak self] in self?.goToToday() }, onOpen: open)
    })]
  }

  func setMonth(_ month: Date) {
    self.month = month
    render()
  }

  func select(_ day: Date) {
    selectedDay = day
    render()
  }

  private func goToToday() {
    month = Date()
    selectedDay = Calendar.current.startOfDay(for: Date())
    render()
  }
}
