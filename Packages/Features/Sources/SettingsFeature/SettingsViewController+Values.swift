import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// The values `SettingsViewController` hands the shared content: what the
/// view model holds now, and bindings that write through it.
extension SettingsViewController {
  var permissions: SettingsPermissions {
    let viewModel = viewModel
    return SettingsPermissions(
      microphone: viewModel.microphone.content,
      notifications: viewModel.notifications.content,
      onMicrophone: { viewModel.tapMicrophone() },
      onNotifications: { viewModel.tapNotifications() })
  }

  func recording(_ preferences: AppPreferences) -> SettingsRecording {
    SettingsRecording(
      sensitivity: binding(\.sensitivity, preferences),
      sleepTalking: binding(\.detectSleepTalking, preferences),
      preserveRawAudio: viewModel.showsDebugRows ? binding(\.preserveRawAudio, preferences) : nil)
  }

  func profile(_ preferences: AppPreferences) -> SettingsProfile {
    let viewModel = viewModel
    return SettingsProfile(onOpen: { viewModel.openProfile() }, briefing: binding(\.briefingEnabled, preferences))
  }

  func storage(_ preferences: AppPreferences) -> SettingsStorage {
    let viewModel = viewModel
    return SettingsStorage(
      limitStorage: binding(\.limitStorage, preferences),
      megabytes: Binding(get: { preferences.storageLimitMB }, set: { viewModel.setStorageLimit(megabytes: $0) }),
      limitDays: binding(\.limitDays, preferences),
      days: binding(\.maxDays, preferences),
      onTestCleanup: viewModel.showsDebugRows ? { viewModel.testCleanup() } : nil)
  }

  func data(_ preferences: AppPreferences) -> SettingsData {
    let viewModel = viewModel
    return SettingsData(
      healthSync: viewModel.hasHealth
        ? Binding(get: { preferences.syncToHealth }, set: { viewModel.setHealthSync($0) })
        : nil,
      onDeleteAll: { viewModel.askToDeleteAll() },
      onAddSampleNights: viewModel.canAddSampleNights ? { viewModel.addSampleNights() } : nil)
  }

  var about: SettingsAbout {
    let viewModel = viewModel
    return SettingsAbout(version: viewModel.version, onRate: viewModel.canRate ? { viewModel.rateApp() } : nil)
  }

  /// The value as drawn now (read here so a change redraws); writes go
  /// through the view model.
  private func binding<Value>(
    _ keyPath: WritableKeyPath<AppPreferences, Value>, _ preferences: AppPreferences) -> Binding<Value>
  {
    let viewModel = viewModel
    let shown = preferences[keyPath: keyPath]
    return Binding(get: { shown }, set: { value in viewModel.change { $0[keyPath: keyPath] = value } })
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
