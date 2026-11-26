import AppShellTestSupport
import FactoryKit
import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import Testing
import UIKit
@testable import AppShell
@testable import RecordingFeature
@testable import ScreenKit
@testable import SettingsFeature

/// The Settings tab shows Settings and the profile editor as a sheet; the
/// App Store row exists only for a brand with a page; Apple Health only for
/// a brand with HealthKit.
struct SettingsFlowTests {
  private func makeFlow(brand: TestBrand = TestBrand()) -> (SettingsFlow, NavigatorSpy) {
    let spy = NavigatorSpy()
    return (AppComposition(container: Container.test(brand: brand)).settingsFlow(navigator: spy), spy)
  }

  private func settings(_ spy: NavigatorSpy) throws -> SettingsViewController {
    guard case let .setRoot(controller) = spy.calls.first, let screen = controller as? SettingsViewController else {
      throw FlowError.unexpected
    }
    return screen
  }

  private enum FlowError: Error {
    case unexpected
  }

  @Test func startShowsSettings() throws {
    let (flow, spy) = makeFlow()
    flow.start()
    _ = try settings(spy)
  }

  @Test func theProfileOpensAsASheetAndClosesItself() throws {
    let (flow, spy) = makeFlow()
    flow.start()
    try settings(spy).viewModel.routes.openProfile()
    guard case let .present(controller, .sheet) = spy.calls.last,
          let editor = controller as? ProfileEditorViewController else { throw FlowError.unexpected }
    editor.viewModel.routes.close()
    #expect(spy.calls.last == .dismiss(controller))
  }

  @Test(arguments: [nil, "123"])
  func rateIsOfferedOnlyWithAnAppStorePage(appStoreID: String?) throws {
    let (flow, spy) = makeFlow(brand: TestBrand(appStoreID: appStoreID))
    flow.start()
    #expect(try (settings(spy).viewModel.routes.rateApp != nil) == (appStoreID != nil))
  }

  @Test func healthRowsFollowTheBrand() throws {
    let (withHealth, healthSpy) = makeFlow(brand: TestBrand(health: FakeHealthAccess()))
    withHealth.start()
    #expect(try settings(healthSpy).viewModel.dependencies.health != nil)
    let (without, spy) = makeFlow()
    without.start()
    #expect(try settings(spy).viewModel.dependencies.health == nil)
  }

  @Test func theReviewLinkIsTheAppStoresWriteAReviewPage() {
    #expect(SettingsFlow.reviewURL(appStoreID: "42")?.absoluteString == "https://apps.apple.com/app/id42?action=write-review")
  }
}

/// The start delay: a countdown with the microphone warm and a notification,
/// back to the prestart on Cancel, the night on Start now.
struct RecordingDelayFlowTests {
  final class Log {
    var scheduled: [Date] = []
    var cancelled = 0
    var screenOn: [Bool] = []
  }

  private func makeFlow() -> (RecordingFlow, NavigatorSpy, FakeAudioCapture, Log) {
    let container = Container.test()
    let capture = FakeAudioCapture()
    let log = Log()
    container.makeAudioCapture.register { { capture } }
    container.deviceServices.register {
      var device = DeviceServices(
        keepScreenOn: { log.screenOn.append($0) }, openSettings: {}, isCharging: { true }, batteryLevel: { nil })
      device.scheduleStartNotification = { log.scheduled.append($0) }
      device.cancelStartNotification = { log.cancelled += 1 }
      return device
    }
    let spy = NavigatorSpy()
    let flow = AppComposition(container: container).recordingFlow(navigator: spy, compactHeight: false) {}
    return (flow, spy, capture, log)
  }

  private func startDelayed(_ flow: RecordingFlow, _ spy: NavigatorSpy) throws -> RecordingCountdownRoutes {
    flow.start()
    guard case let .setRoot(controller) = spy.calls.last,
          let prestart = controller as? RecordingPrestartViewController else { throw FlowError.unexpected }
    var preferences = AppPreferences()
    preferences.recordingDelayMinutes = 15
    prestart.viewModel.routes.start(preferences)
    guard case let .setRoot(next) = spy.calls.last,
          let countdown = next as? RecordingCountdownViewController else { throw FlowError.unexpected }
    return countdown.viewModel.routes
  }

  private enum FlowError: Error {
    case unexpected
  }

  @Test func aDelayShowsTheCountdownWithTheMicrophoneWarm() throws {
    let (flow, spy, capture, log) = makeFlow()
    _ = try startDelayed(flow, spy)
    #expect(capture.calls == [.warmUp])
    #expect(log.scheduled.count == 1)
    #expect(abs(log.scheduled[0].timeIntervalSinceNow - 15 * 60) < 5)
    #expect(log.screenOn == [true])
    #expect(flow.model == nil)
  }

  @Test func cancelGoesBackToThePrestart() throws {
    let (flow, spy, capture, log) = makeFlow()
    try startDelayed(flow, spy).cancel()
    #expect(capture.calls == [.warmUp, .coolDown])
    #expect(log.cancelled == 1)
    #expect(log.screenOn == [true, false])
    guard case let .setRoot(controller) = spy.calls.last else { throw FlowError.unexpected }
    #expect(controller is RecordingPrestartViewController)
  }

  @Test func startNowBeginsTheNightOnTheWarmCapture() throws {
    let (flow, spy, _, log) = makeFlow()
    try startDelayed(flow, spy).start()
    #expect(log.cancelled == 1)
    #expect(flow.model != nil)
    guard case let .setRoot(controller) = spy.calls.last else { throw FlowError.unexpected }
    #expect(controller is BedsideClockViewController)
  }
}
