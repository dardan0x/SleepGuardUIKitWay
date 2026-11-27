import AVFAudio
import SettingsFeature
import SleepGuardDesignKit
import SleepNotifications
import UIKit
import UserNotifications

/// The app-wide device switches, in one place: the screen staying on, the
/// Settings link, the charger and the battery, the permissions Settings shows,
/// the start delay's notification. Plain closures, so flow tests swap them;
/// `live` is the only code here that touches `UIApplication`.
nonisolated struct DeviceServices: Sendable {
  /// Keeps the screen on (the bedside clock) or lets it sleep again.
  var keepScreenOn: @MainActor @Sendable (Bool) -> Void
  /// This app's page in Settings, to allow the microphone.
  var openSettings: @MainActor @Sendable () -> Void
  /// Plugged in or full. Always true on the simulator, as in SleepGuard.
  var isCharging: @MainActor @Sendable () -> Bool
  /// 0...1, or `nil` when unknown (the simulator).
  var batteryLevel: @MainActor @Sendable () -> Float?
  var microphone: @MainActor @Sendable () -> PermissionState = { .notDetermined }
  var notifications: @MainActor @Sendable () async -> PermissionState = { .notDetermined }
  var requestNotifications: @MainActor @Sendable () async -> Bool = { false }
  /// "The night is starting" at `date`, for the start delay (one at a time).
  var scheduleStartNotification: @MainActor @Sendable (Date) -> Void = { _ in }
  var cancelStartNotification: @MainActor @Sendable () -> Void = {}
  var openURL: @MainActor @Sendable (URL) -> Void = { _ in }
  /// "1.4.0".
  var appVersion: @MainActor @Sendable () -> String = { "" }

  static let live = DeviceServices(
    keepScreenOn: { UIApplication.shared.isIdleTimerDisabled = $0 },
    openSettings: {
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
    },
    isCharging: {
      #if targetEnvironment(simulator)
      return true
      #else
      UIDevice.current.isBatteryMonitoringEnabled = true
      return UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
      #endif
    },
    batteryLevel: {
      UIDevice.current.isBatteryMonitoringEnabled = true
      let level = UIDevice.current.batteryLevel
      return level >= 0 ? level : nil
    },
    microphone: {
      switch AVAudioApplication.shared.recordPermission {
      case .granted: .granted
      case .denied: .denied
      default: .notDetermined
      }
    },
    notifications: {
      switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
      case .authorized, .provisional, .ephemeral: .granted
      case .denied: .denied
      default: .notDetermined
      }
    },
    requestNotifications: {
      await (try? UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    },
    scheduleStartNotification: { StartNotification.schedule(startingAt: $0) },
    cancelStartNotification: { StartNotification.cancel() },
    openURL: { UIApplication.shared.open($0) },
    appVersion: { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "" })
}
