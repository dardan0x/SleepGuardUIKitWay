import ScreenKit
import SettingsFeature
import SleepDomain
import StatisticsFeature
import UIKit

/// The Statistics tab: the dashboard, Trends, Last 7 Nights, the calendar, and
/// a night's detail. Starting a recording isn't this tab's job: it goes up to
/// `AppCoordinator`, which owns the recording flow.
final class StatisticsFlow: NightDetailHosting {
  let tab = AppTab.statistics
  let navigator: any Navigator
  let nightDetail: NightDetailNavigation
  private let screens: StatisticsFactory
  private let settings: SettingsFactory
  private let preferences: any PreferencesStorePort
  private let onStartRecording: @MainActor () -> Void
  /// Counting a dismissed profile prompt; awaited by tests.
  private(set) var dismissing: Task<Void, Never>?

  init(
    navigator: any Navigator,
    screens: StatisticsFactory,
    settings: SettingsFactory,
    preferences: any PreferencesStorePort,
    nightDetail: NightDetailNavigation,
    onStartRecording: @escaping @MainActor () -> Void)
  {
    self.navigator = navigator
    self.screens = screens
    self.settings = settings
    self.preferences = preferences
    self.nightDetail = nightDetail
    self.onStartRecording = onStartRecording
  }

  func start() {
    navigator.setRoot(screens.makeDashboard(
      routes: StatisticsRoutes(
        startRecording: { [weak self] in self?.onStartRecording() },
        showTrends: { [weak self] in self?.showTrends() },
        showCalendar: { [weak self] in self?.showCalendar() },
        showLastSevenNights: { [weak self] in self?.showLastSevenNights() },
        showStagesInfo: { [weak self] stages in self?.nightDetail.showStagesInfo(stages) },
        openProfile: { [weak self] in self?.openProfile() },
        dismissProfilePrompt: { [weak self] in self?.dismissProfilePrompt() })))
  }

  /// The profile editor, as from Settings.
  private func openProfile() {
    navigator.present(style: .sheet(detents: [.large])) { close in
      settings.makeProfileEditor(routes: ProfileEditorRoutes(close: close))
    }
  }

  private func dismissProfilePrompt() {
    dismissing = Task { [preferences] in
      var stored = await preferences.load()
      stored.profilePromptDismissCount += 1
      await preferences.save(stored)
    }
  }

  private func showTrends() {
    navigator.push(screens.makeTrends())
  }

  /// Internal: a link opens it too (`AppRoute.lastSevenNights`).
  func showLastSevenNights() {
    navigator.push(screens.makeLastSevenNights(routes: nightListRoutes))
  }

  private func showCalendar() {
    navigator.push(screens.makeCalendar(routes: nightListRoutes))
  }

  private var nightListRoutes: NightListRoutes {
    NightListRoutes(openNight: { [weak self] night in self?.nightDetail.show(night) })
  }
}
