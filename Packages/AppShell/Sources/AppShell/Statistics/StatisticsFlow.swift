import FactoryKit
import ScreenKit
import StatisticsFeature
import UIKit

/// The Statistics tab: the dashboard, Trends, Last 7 Nights, the calendar, and
/// a night's detail. Starting a recording isn't this tab's job: it goes up to
/// `AppCoordinator`, which owns the recording flow.
final class StatisticsFlow: TabFlow {
  let tab = AppTab.statistics
  let navigator: any Navigator
  let nightDetail: NightDetailNavigation
  private let screens: StatisticsComposer
  private let onStartRecording: @MainActor () -> Void

  init(navigator: any Navigator, container: Container, onStartRecording: @escaping @MainActor () -> Void) {
    self.navigator = navigator
    self.onStartRecording = onStartRecording
    screens = StatisticsComposer(container: container)
    nightDetail = NightDetailNavigation(navigator: navigator, container: container)
  }

  func start() {
    navigator.setRoot(screens.makeDashboard(
      routes: StatisticsRoutes(
        startRecording: { [weak self] in self?.onStartRecording() },
        showTrends: { [weak self] in self?.showTrends() },
        showLastSevenNights: { [weak self] in self?.showLastSevenNights() },
        showStagesInfo: { [weak self] stages in self?.nightDetail.showStagesInfo(stages) }),
      onCalendar: { [weak self] in self?.showCalendar() }))
  }

  private func showTrends() {
    navigator.push(screens.makeTrends())
  }

  private func showLastSevenNights() {
    navigator.push(screens.makeLastSevenNights(routes: nightListRoutes))
  }

  private func showCalendar() {
    navigator.push(screens.makeCalendar(routes: nightListRoutes))
  }

  private var nightListRoutes: NightListRoutes {
    NightListRoutes(openNight: { [weak self] night in self?.nightDetail.show(night) })
  }
}
