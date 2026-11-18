import FactoryKit
import ScreenKit
import SettingsFeature
import SleepDomain
import StatisticsFeature
import UIKit

/// The Statistics tab: the dashboard, Trends, Last 7 Nights, the calendar, and
/// a night's detail. Starting a recording isn't this tab's job: it goes up to
/// `AppCoordinator`, which owns the recording flow.
final class StatisticsFlow: TabFlow {
  let tab = AppTab.statistics
  let navigator: any Navigator
  let nightDetail: NightDetailNavigation
  private let screens: StatisticsFactory
  private let settings: SettingsFactory
  private let profilePrompt: ProfilePromptCheck
  private let onStartRecording: @MainActor () -> Void
  /// Counting a dismissed profile prompt; awaited by tests.
  private(set) var dismissing: Task<Void, Never>?

  init(navigator: any Navigator, container: Container, onStartRecording: @escaping @MainActor () -> Void) {
    self.navigator = navigator
    self.onStartRecording = onStartRecording
    screens = StatisticsFactory(container: container)
    settings = SettingsFactory(container: container)
    profilePrompt = container.profilePromptCheck()
    nightDetail = NightDetailNavigation(navigator: navigator, container: container)
  }

  func start() {
    navigator.setRoot(screens.makeDashboard(
      routes: StatisticsRoutes(
        startRecording: { [weak self] in self?.onStartRecording() },
        showTrends: { [weak self] in self?.showTrends() },
        showLastSevenNights: { [weak self] in self?.showLastSevenNights() },
        showStagesInfo: { [weak self] stages in self?.nightDetail.showStagesInfo(stages) },
        openProfile: { [weak self] in self?.openProfile() },
        dismissProfilePrompt: { [weak self] in self?.dismissProfilePrompt() }),
      onCalendar: { [weak self] in self?.showCalendar() }))
  }

  /// The profile editor, as from Settings.
  private func openProfile() {
    navigator.present(
      settings.makeProfileEditor(routes: ProfileEditorRoutes(close: { [weak self] in self?.navigator.dismiss() })),
      style: .sheet(detents: [.large]))
  }

  private func dismissProfilePrompt() {
    dismissing = Task { [profilePrompt] in await profilePrompt.dismissed() }
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
