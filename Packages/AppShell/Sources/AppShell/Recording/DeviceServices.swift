import UIKit

/// The app-wide device switches recording needs, in one place: the screen
/// staying on, the Settings link, the charger. Plain closures, so flow tests
/// swap them; `live` is the only code here that touches `UIApplication`.
nonisolated struct DeviceServices: Sendable {
  /// Keeps the screen on (the bedside clock) or lets it sleep again.
  var keepScreenOn: @MainActor @Sendable (Bool) -> Void
  /// This app's page in Settings, to allow the microphone.
  var openSettings: @MainActor @Sendable () -> Void
  /// Plugged in or full. Always true on the simulator, as in SleepGuard.
  var isCharging: @MainActor @Sendable () -> Bool

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
    })
}
