import AppShellTestSupport
import FactoryKit
import Foundation
import SleepDomain
import SleepDomainTestSupport
import Testing
@testable import AppShell

/// The pieces split out of `RecordingFlow` (F13-T10): the device around a
/// night, and the interrupter's settings.
@MainActor
struct NightLifecycleTests {
  private final class Device {
    var screenOn: [Bool] = []
    var scheduled: [Date] = []
    var cancels = 0
    var battery: Float?
  }

  private func lifecycle(_ device: Device) -> NightLifecycle {
    NightLifecycle(device: DeviceServices(
      keepScreenOn: { device.screenOn.append($0) }, openSettings: {}, isCharging: { false },
      batteryLevel: { device.battery },
      scheduleStartNotification: { device.scheduled.append($0) },
      cancelStartNotification: { device.cancels += 1 }))
  }

  @Test func aCancelledDelayCoolsTheMicrophoneAndLetsTheScreenSleep() {
    let device = Device()
    let capture = FakeAudioCapture()
    let lifecycle = lifecycle(device)
    let target = Date(timeIntervalSinceReferenceDate: 1000)

    lifecycle.beginDelay(capture: capture, until: target)
    lifecycle.cancelDelay()

    #expect(capture.calls == [.warmUp, .coolDown])
    #expect(device.scheduled == [target] && device.cancels == 1)
    #expect(device.screenOn == [true, false])
    #expect(lifecycle.endDelay() == nil)
  }

  @Test func theDelayHandsOverTheWarmCaptureOnce() {
    let device = Device()
    let capture = FakeAudioCapture()
    let lifecycle = lifecycle(device)
    lifecycle.beginDelay(capture: capture, until: .now)

    #expect(lifecycle.endDelay() === capture)
    #expect(lifecycle.endDelay() == nil)
    #expect(capture.calls == [.warmUp])
  }

  @Test func theScreenStaysOnFromTheDelayThroughTheNightThenSleeps() {
    let device = Device()
    let lifecycle = lifecycle(device)
    lifecycle.beginDelay(capture: FakeAudioCapture(), until: .now)
    _ = lifecycle.endDelay()
    lifecycle.nightStarted {}
    lifecycle.nightEnded()
    lifecycle.nightEnded()
    #expect(device.screenOn == [true, false])
  }

  @Test func lowBatteryIsAtOrUnderTwoPercent() {
    let device = Device()
    let lifecycle = lifecycle(device)
    #expect(lifecycle.lowBatteryLevelNow == nil) // unknown (simulator)
    device.battery = 0.03
    #expect(lifecycle.lowBatteryLevelNow == nil)
    device.battery = 0.02
    #expect(lifecycle.lowBatteryLevelNow == 0.02)
  }

  /// Opening the settings twice quickly: the first load is cancelled, not
  /// left running (the reassigned task used to leak).
  @Test func aNewInterrupterTaskCancelsTheOneBefore() async {
    let container = Container.test(brand: TestBrand(snoreInterrupter: true))
    let spy = NavigatorSpy()
    let flow = AppComposition(container: container).recordingFlow(navigator: spy, compactHeight: false) {}
    flow.interrupter.open { _ in }
    let first = flow.interrupter.task
    flow.interrupter.open { _ in }
    #expect(first?.isCancelled == true)
    await flow.interrupter.task?.value
    #expect(spy.calls.filter { if case .present = $0 { true } else { false } }.count == 1)
  }
}
