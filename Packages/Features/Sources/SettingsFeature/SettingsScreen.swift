import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI

/// Settings, drawn by the shared `SettingsContent`. Holds the preferences
/// while shown and writes each change back; asks before deleting everything
/// and before lowering the storage limit (which removes audio at once).
/// Rows for what the brand lacks (Apple Health, a Watch, an App Store page)
/// aren't shown. The values handed to the content are built in
/// `SettingsScreen+Values.swift`, what its taps do in `+Actions.swift`.
public struct SettingsScreen: View {
  enum Alert: Equatable {
    case deleteAll
    case lowerLimit(Int)
    case cleanup(EnforceStorageLimits.Report)
    case failed
  }

  let dependencies: SettingsDependencies
  let routes: SettingsRoutes
  @State var preferences: AppPreferences?
  @State var microphone: PermissionState = .notDetermined
  @State var notifications: PermissionState = .notDetermined
  @State var alert: Alert?

  public init(dependencies: SettingsDependencies, routes: SettingsRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public var body: some View {
    Group {
      if preferences != nil {
        SettingsContent(
          permissions: permissions, recording: recording, profile: profile, watch: nil,
          storage: storage, data: data, about: about)
      } else {
        Color.clear
      }
    }
    .task {
      preferences = await dependencies.preferences.load()
      await refreshPermissions()
    }
    .alert(Strings.settingsDeleteAllConfirmTitle, isPresented: isShowing { $0 == .deleteAll }) {
      Button(Strings.actionCancel, role: .cancel) {}
      Button(Strings.actionDeleteAll, role: .destructive) { deleteAll() }
    } message: {
      Text(Strings.settingsDeleteAllConfirmMessage)
    }
    .alert(Strings.settingsLowerStorageLimitTitle, isPresented: isShowing { if case .lowerLimit = $0 { true } else { false } }) {
      Button(Strings.actionCancel, role: .cancel) {}
      Button(Strings.actionDelete, role: .destructive) { confirmLowerLimit() }
    } message: {
      Text(Strings.settingsLowerStorageLimitMessage)
    }
    .alert(Strings.settingsTestCleanup, isPresented: isShowing { if case .cleanup = $0 { true } else { false } }) {
      Button(Strings.actionOk) {}
    } message: {
      if case let .cleanup(report) = alert {
        Text(String(
          format: Strings.settingsTestCleanupResultFormat, report.filesRemoved, Int(report.bytesRemoved / 1_024 / 1_024),
          report.nightsAffected, report.dayLimitNights, report.sizeLimitNights))
      }
    }
    .alert(Strings.recordingsErrorTitle, isPresented: isShowing { $0 == .failed }) {
      Button(Strings.actionOk) {}
    } message: {
      Text(Strings.recordingsErrorMessage)
    }
  }
}
