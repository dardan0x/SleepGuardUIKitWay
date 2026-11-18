import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import UIKit

/// Settings, drawn by the shared `SettingsContent`. Holds the preferences
/// while shown and writes each change back; asks before deleting everything
/// and before lowering the storage limit (which removes audio at once).
/// Rows for what the brand lacks (Apple Health, a Watch, an App Store page)
/// aren't shown. The values handed to the content are built in
/// `SettingsViewController+Values.swift`.
public final class SettingsViewController: ScreenController {
  let dependencies: SettingsDependencies
  let routes: SettingsRoutes
  var preferences: AppPreferences?
  var microphone: PermissionState = .notDetermined
  var notifications: PermissionState = .notDetermined
  /// The last write or cleanup, awaited by tests.
  private(set) var working: Task<Void, Never>?

  public init(dependencies: SettingsDependencies, routes: SettingsRoutes, theme: Theme, chrome: ScreenChrome) {
    self.dependencies = dependencies
    self.routes = routes
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    run { [dependencies] screen in
      screen.preferences = await dependencies.preferences.load()
      await screen.refreshPermissions()
    }
  }

  func redraw() {
    guard preferences != nil else { return }
    render(SettingsContent(
      permissions: permissions, recording: recording, profile: profile, watch: nil,
      storage: storage, data: data, about: about))
  }

  /// Runs `work` for this screen, after the work before it.
  func run(_ work: @escaping @MainActor (SettingsViewController) async -> Void) {
    let previous = working
    working = Task { [weak self] in
      await previous?.value
      guard let self else { return }
      await work(self)
      redraw()
    }
  }

  func refreshPermissions() async {
    microphone = dependencies.microphone()
    notifications = await dependencies.notifications()
  }

  /// Writes a change, here and in the store.
  func change(_ update: (inout AppPreferences) -> Void) {
    guard var preferences else { return }
    update(&preferences)
    self.preferences = preferences
    redraw()
    let (store, saved) = (dependencies.preferences, preferences)
    run { _ in await store.save(saved) }
  }

  func deleteAll() {
    run { [dependencies] screen in
      do {
        try await dependencies.deleteAllData()
      } catch {
        screen.alert(Strings.recordingsErrorTitle, Strings.recordingsErrorMessage)
      }
    }
  }

  /// After the new limit is saved (`change` queues the write first).
  func enforceLimits(showingReport: Bool) {
    run { [dependencies] screen in
      do {
        let report = try await dependencies.enforceStorageLimits()
        if showingReport {
          screen.alert(Strings.settingsTestCleanup, String(
            format: Strings.settingsTestCleanupResultFormat, report.filesRemoved, Int(report.bytesRemoved / 1_024 / 1_024),
            report.nightsAffected, report.dayLimitNights, report.sizeLimitNights))
        }
      } catch {
        screen.alert(Strings.recordingsErrorTitle, Strings.recordingsErrorMessage)
      }
    }
  }

  // MARK: - Alerts

  func confirmDeleteAll() {
    present(confirmation(
      Strings.settingsDeleteAllConfirmTitle, Strings.settingsDeleteAllConfirmMessage, action: Strings.actionDeleteAll)
    { [weak self] in self?.deleteAll() }, animated: true)
  }

  func confirmLowerLimit(to megabytes: Int) {
    present(confirmation(
      Strings.settingsLowerStorageLimitTitle, Strings.settingsLowerStorageLimitMessage, action: Strings.actionDelete)
    { [weak self] in
      self?.change { $0.storageLimitMB = megabytes }
      self?.enforceLimits(showingReport: false)
    }, animated: true)
  }

  /// Cancel and a destructive `action`.
  func confirmation(_ title: String, _ message: String, action: String, perform: @escaping () -> Void) -> UIAlertController {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionCancel, style: .cancel))
    alert.addAction(UIAlertAction(title: action, style: .destructive) { _ in perform() })
    return alert
  }

  private func alert(_ title: String, _ message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionOk, style: .default))
    present(alert, animated: true)
  }
}
