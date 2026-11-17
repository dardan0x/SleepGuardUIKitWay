import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// The values `SettingsScreen` hands the shared content.
extension SettingsScreen {
  var permissions: SettingsPermissions {
    SettingsPermissions(
      microphone: microphone.content,
      notifications: notifications.content,
      onMicrophone: { tapped(microphone, request: dependencies.requestMicrophone) },
      onNotifications: { tapped(notifications, request: dependencies.requestNotifications) })
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
        get: { preferences?.storageLimitMB ?? StorageLimits.defaultMegabytes },
        set: { megabytes in
          // A lower limit removes audio, so it asks first.
          if megabytes < (preferences?.storageLimitMB ?? 0) {
            alert = .lowerLimit(megabytes)
          } else {
            change { $0.storageLimitMB = megabytes }
          }
        }),
      limitDays: binding(\.limitDays),
      days: binding(\.maxDays),
      onTestCleanup: dependencies.showsDebugRows ? { enforceLimits(showingReport: true) } : nil)
  }

  var data: SettingsData {
    SettingsData(
      healthSync: dependencies.health.map { health in
        Binding(
          get: { preferences?.syncToHealth ?? false },
          set: { isOn in
            guard isOn else { return change { $0.syncToHealth = false } }
            // On only once Health allows it.
            Task {
              let granted = await health.requestAuthorization()
              change { $0.syncToHealth = granted }
            }
          })
      },
      onDeleteAll: { alert = .deleteAll },
      onAddSampleNights: routes.addSampleNights)
  }

  var about: SettingsAbout {
    SettingsAbout(version: dependencies.version, onRate: routes.rateApp)
  }

  private func binding<Value>(_ keyPath: WritableKeyPath<AppPreferences, Value>) -> Binding<Value> {
    Binding(
      get: { preferences.map { $0[keyPath: keyPath] } ?? AppPreferences()[keyPath: keyPath] },
      set: { value in change { $0[keyPath: keyPath] = value } })
  }

  /// Not asked yet: ask. Denied: the system Settings.
  private func tapped(_ state: PermissionState, request: @escaping @MainActor () async -> Bool) {
    switch state {
    case .notDetermined:
      Task {
        _ = await request()
        await refreshPermissions()
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
