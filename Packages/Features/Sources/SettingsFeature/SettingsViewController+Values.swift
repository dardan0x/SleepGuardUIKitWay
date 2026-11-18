import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// The values `SettingsViewController` hands the shared content. Each binding
/// writes through the screen, which redraws.
extension SettingsViewController {
  var permissions: SettingsPermissions {
    SettingsPermissions(
      microphone: microphone.content,
      notifications: notifications.content,
      onMicrophone: { [weak self] in self?.tapped(\.microphone, request: self?.dependencies.requestMicrophone) },
      onNotifications: { [weak self] in self?.tapped(\.notifications, request: self?.dependencies.requestNotifications) })
  }

  var recording: SettingsRecording {
    SettingsRecording(
      sensitivity: binding(\.sensitivity),
      sleepTalking: binding(\.detectSleepTalking),
      preserveRawAudio: dependencies.showsDebugRows ? binding(\.preserveRawAudio) : nil)
  }

  var profile: SettingsProfile {
    SettingsProfile(onOpen: routes.openProfile, briefing: binding(\.briefingEnabled))
  }

  var storage: SettingsStorage {
    SettingsStorage(
      limitStorage: binding(\.limitStorage),
      megabytes: Binding(
        get: { [weak self] in self?.preferences?.storageLimitMB ?? StorageLimits.defaultMegabytes },
        set: { [weak self] megabytes in
          guard let self else { return }
          // A lower limit removes audio, so it asks first.
          if megabytes < (preferences?.storageLimitMB ?? 0) {
            confirmLowerLimit(to: megabytes)
          } else {
            change { $0.storageLimitMB = megabytes }
          }
        }),
      limitDays: binding(\.limitDays),
      days: binding(\.maxDays),
      onTestCleanup: dependencies.showsDebugRows ? { [weak self] in self?.enforceLimits(showingReport: true) } : nil)
  }

  var data: SettingsData {
    SettingsData(
      healthSync: dependencies.health.map { health in
        Binding(
          get: { [weak self] in self?.preferences?.syncToHealth ?? false },
          set: { [weak self] isOn in
            guard isOn else { return self?.change { $0.syncToHealth = false } ?? () }
            // On only once Health allows it.
            self?.run { screen in
              let granted = await health.requestAuthorization()
              screen.change { $0.syncToHealth = granted }
            }
          })
      },
      onDeleteAll: { [weak self] in self?.confirmDeleteAll() },
      onAddSampleNights: routes.addSampleNights)
  }

  var about: SettingsAbout {
    SettingsAbout(version: dependencies.version, onRate: routes.rateApp)
  }

  private func binding<Value>(_ keyPath: WritableKeyPath<AppPreferences, Value>) -> Binding<Value> {
    Binding(
      get: { [weak self] in self?.preferences.map { $0[keyPath: keyPath] } ?? AppPreferences()[keyPath: keyPath] },
      set: { [weak self] value in self?.change { $0[keyPath: keyPath] = value } })
  }

  /// Not asked yet: ask. Denied: the system Settings.
  private func tapped(
    _ state: KeyPath<SettingsViewController, PermissionState>, request: (@MainActor () async -> Bool)?)
  {
    switch self[keyPath: state] {
    case .notDetermined:
      guard let request else { return }
      run { screen in
        _ = await request()
        await screen.refreshPermissions()
      }
    case .denied:
      routes.openSystemSettings()
    case .granted:
      break
    }
  }
}

extension PermissionState {
  var content: SettingsPermission {
    switch self {
    case .granted: .granted
    case .denied: .denied
    case .notDetermined: .notDetermined
    }
  }
}
