import Foundation
import SleepDomain
import SleepLogging

/// The device around a night: the microphone kept warm and a notification
/// through the start delay, the screen kept on, the battery watched while
/// recording. Owned by `RecordingFlow`, which decides the steps.
final class NightLifecycle {
  /// SleepGuard's low-battery line: at or under 2%, the night is stopped and
  /// kept before the phone dies.
  static let lowBatteryLevel: Float = 0.02
  /// How often the battery is checked while recording.
  static let batteryCheckInterval: Duration = .seconds(30)

  private let device: DeviceServices
  private var batteryWatch: Task<Void, Never>?
  /// The capture kept warm during the start delay.
  private var warmCapture: (any AudioCapturePort)?
  private var keepsScreenOn = false

  init(device: DeviceServices) {
    self.device = device
  }

  deinit {
    batteryWatch?.cancel()
  }

  /// The start delay: the microphone stays warm (so the app keeps running
  /// with the screen locked), a notification says when the night starts, and
  /// the screen stays on as on the bedside clock.
  func beginDelay(capture: any AudioCapturePort, until target: Date) {
    do {
      try capture.warmUp()
    } catch {
      Log.app.error("Warm-up failed; the countdown may pause in the background: \(error.localizedDescription, privacy: .public)")
    }
    warmCapture = capture
    device.scheduleStartNotification(target)
    keepScreenOn(true)
  }

  /// The delay was cancelled: nothing stays warm or on.
  func cancelDelay() {
    warmCapture?.coolDown()
    warmCapture = nil
    device.cancelStartNotification()
    keepScreenOn(false)
  }

  /// The delay is over: the warm capture, for the night (`nil` if none).
  func endDelay() -> (any AudioCapturePort)? {
    defer { warmCapture = nil }
    device.cancelStartNotification()
    return warmCapture
  }

  /// The night is recording: the screen stays on, and `check` runs every
  /// `batteryCheckInterval` until `nightEnded`.
  func nightStarted(check: @escaping @MainActor () -> Void) {
    keepScreenOn(true)
    batteryWatch?.cancel()
    batteryWatch = Task {
      while !Task.isCancelled {
        try? await Task.sleep(for: Self.batteryCheckInterval)
        if !Task.isCancelled { check() }
      }
    }
  }

  /// At or under `lowBatteryLevel`: the level, else `nil`.
  var lowBatteryLevelNow: Float? {
    device.batteryLevel().flatMap { $0 <= Self.lowBatteryLevel ? $0 : nil }
  }

  /// Recording is over: the screen may sleep, the battery isn't watched.
  func nightEnded() {
    batteryWatch?.cancel()
    batteryWatch = nil
    keepScreenOn(false)
  }

  private func keepScreenOn(_ on: Bool) {
    guard on != keepsScreenOn else { return }
    keepsScreenOn = on
    device.keepScreenOn(on)
  }
}
