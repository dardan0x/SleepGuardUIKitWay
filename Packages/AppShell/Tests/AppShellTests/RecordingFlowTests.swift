import AppShellTestSupport
import FactoryKit
import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import SleepGuardDesignKit
import Testing
import UIKit
@testable import AppShell
@testable import RecordingFeature
@testable import ScreenKit

/// The recording flow over a navigator spy: each step replaces the last, the
/// screen stays on only while recording, and a night ends saved or discarded
/// with its clips.
struct RecordingFlowTests {
  private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  /// What the flow asked of the device.
  final class DeviceLog {
    var screenOn: [Bool] = []
    var settingsOpened = 0
    var battery: Float? = 0.8
  }

  private struct Harness {
    let flow: RecordingFlow
    let spy: NavigatorSpy
    let repository: FakeSessionRepository
    let files: FakeSessionFileStore
    let checkpoints: FakeRecordingCheckpointStore
    let device: DeviceLog
    let closed: () -> Int
  }

  private func makeFlow() -> Harness {
    let repository = FakeSessionRepository()
    let files = FakeSessionFileStore()
    let checkpoints = FakeRecordingCheckpointStore()
    let device = DeviceLog()
    let container = Container.test(repository: repository)
    container.sessionFileStore.register { files }
    container.checkpointStore.register { checkpoints }
    container.makeAudioCapture.register { { FakeAudioCapture() } }
    container.deviceServices.register {
      DeviceServices(
        keepScreenOn: { device.screenOn.append($0) },
        openSettings: { device.settingsOpened += 1 },
        isCharging: { true },
        batteryLevel: { device.battery })
    }
    let spy = NavigatorSpy()
    var closes = 0
    let flow = RecordingFlow(navigator: spy, container: container, compactHeight: false) { closes += 1 }
    return Harness(
      flow: flow, spy: spy, repository: repository, files: files, checkpoints: checkpoints, device: device,
      closed: { closes })
  }

  private func night(minutes: Double, clips: [String] = []) -> Night {
    Night(
      start: start, end: start.addingTimeInterval(minutes * 60),
      events: clips.enumerated().map { index, clip in
        NightEvent(start: start.addingTimeInterval(Double(index) * 60), duration: 10, intensity: .light, clipFileName: clip)
      })
  }

  private func root<Screen>(_ spy: NavigatorSpy, as _: Screen.Type) throws -> HostingScreen<Screen> {
    guard case let .setRoot(controller) = spy.calls.last else {
      throw FlowError.unexpected(spy.calls)
    }
    guard let screen = controller as? HostingScreen<Screen> else { throw FlowError.unexpected(spy.calls) }
    return screen
  }

  private enum FlowError: Error {
    case unexpected([NavigatorSpy.Call])
  }

  @Test func startShowsThePrestart() throws {
    let h = makeFlow()
    h.flow.start()
    _ = try root(h.spy, as: RecordingPrestartScreen.self)
    #expect(h.spy.calls.count == 1)
    #expect(h.device.screenOn.isEmpty)
  }

  @Test func cancelAndSettingsGoToTheShellAndDevice() throws {
    let h = makeFlow()
    h.flow.start()
    let routes = try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes
    routes.openSettings()
    #expect(h.device.settingsOpened == 1)
    routes.cancel()
    #expect(h.closed() == 1)
  }

  @Test func startingReplacesThePrestartWithTheBedsideClockAndKeepsTheScreenOn() throws {
    let h = makeFlow()
    h.flow.start()
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start(AppPreferences())
    _ = try root(h.spy, as: BedsideClockScreen.self)
    #expect(h.flow.model != nil)
    #expect(h.device.screenOn == [true])
  }

  @Test func aFinishedNightShowsItsSummaryAndLetsTheScreenSleep() throws {
    let h = makeFlow()
    h.flow.start()
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start(AppPreferences())
    try root(h.spy, as: BedsideClockScreen.self).rootView.content.routes.finished(night(minutes: 60))
    let summary = try root(h.spy, as: SessionSummaryScreen.self)
    #expect(summary.rootView.content.night.duration == 3600)
    #expect(h.device.screenOn == [true, false])
    #expect(h.flow.model == nil)
  }

  @Test func savingCommitsTheNightAndCloses() async throws {
    let h = makeFlow()
    let night = night(minutes: 60)
    try showSummary(night, in: h).save(night)
    await h.flow.finishing?.value
    #expect(await h.repository.savedIDs == [night.id])
    #expect(h.closed() == 1)
  }

  @Test func aFailedSaveSaysSoAndStaysOnTheSummary() async throws {
    struct Broken: Error {}
    let h = makeFlow()
    await h.repository.failNextCall(with: Broken())
    let night = night(minutes: 60)
    try showSummary(night, in: h).save(night)
    await h.flow.finishing?.value
    guard case let .present(alert as UIAlertController, .alert) = h.spy.calls.last else {
      Issue.record("expected an alert, got \(h.spy.calls)")
      return
    }
    #expect(alert.title == Strings.saveFailed)
    #expect(h.closed() == 0)
  }

  @Test func discardingTheSummaryRemovesItsClipsAndCloses() async throws {
    let h = makeFlow()
    let night = night(minutes: 60, clips: ["a.m4a", "b.m4a"])
    try showSummary(night, in: h).discard(night)
    await h.flow.finishing?.value
    #expect(await h.files.removed == ["a.m4a", "b.m4a"])
    #expect(await h.repository.savedIDs.isEmpty)
    #expect(h.closed() == 1)
  }

  @Test func stoppingEarlyDiscardsTheClips() async throws {
    let h = makeFlow()
    h.flow.start()
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start(AppPreferences())
    try root(h.spy, as: BedsideClockScreen.self).rootView.content.routes.discarded(night(minutes: 1, clips: ["a.caf"]))
    await h.flow.finishing?.value
    #expect(await h.files.removed == ["a.caf"])
    #expect(h.device.screenOn == [true, false])
    #expect(h.closed() == 1)
  }

  @Test func aStartThatFailedClosesWithNothingToRemove() async throws {
    let h = makeFlow()
    h.flow.start()
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start(AppPreferences())
    try root(h.spy, as: BedsideClockScreen.self).rootView.content.routes.discarded(nil)
    await h.flow.finishing?.value
    #expect(await h.files.removed.isEmpty)
    #expect(h.closed() == 1)
  }

  // MARK: - Recovery and low battery (F7-T7)

  @Test func aRecoveredNightStartsAtItsSummary() throws {
    let h = makeFlow()
    let night = night(minutes: 300, clips: ["a.m4a"])
    h.flow.start(recovering: night)
    #expect(try root(h.spy, as: SessionSummaryScreen.self).rootView.content.night == night)
    #expect(h.spy.calls.count == 1)
    #expect(h.device.screenOn.isEmpty)
  }

  @Test func savingOrDiscardingClearsTheCheckpoint() async throws {
    let saving = makeFlow()
    let night = night(minutes: 60)
    await saving.checkpoints.save(night)
    saving.flow.start(recovering: night)
    try root(saving.spy, as: SessionSummaryScreen.self).rootView.content.routes.save(night)
    await saving.flow.finishing?.value
    #expect(await saving.checkpoints.night == nil)

    let discarding = makeFlow()
    await discarding.checkpoints.save(night)
    discarding.flow.start(recovering: night)
    try root(discarding.spy, as: SessionSummaryScreen.self).rootView.content.routes.discard(night)
    await discarding.flow.finishing?.value
    #expect(await discarding.checkpoints.night == nil)
  }

  /// At 2% the night is stopped, kept as a low-battery night and summarised.
  @Test func lowBatteryStopsTheNightAndShowsItsSummary() async throws {
    let h = makeFlow()
    h.flow.start()
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start(AppPreferences())
    let model = try #require(h.flow.model)
    let running = Task { await model.run() }
    try await waitUntil { model.phase == .recording }

    h.device.battery = 0.5
    h.flow.checkBattery()
    #expect(h.flow.finishing == nil)

    h.device.battery = 0.02
    h.flow.checkBattery()
    await h.flow.finishing?.value
    await running.value
    let summary = try root(h.spy, as: SessionSummaryScreen.self)
    #expect(summary.rootView.content.night.endReason == .lowBattery)
    #expect(await h.checkpoints.night?.endReason == .lowBattery)
    #expect(h.device.screenOn == [true, false])
  }

  @Test func anUnknownBatteryLevelNeverStopsTheNight() async throws {
    let h = makeFlow()
    h.device.battery = nil
    h.flow.start()
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start(AppPreferences())
    let model = try #require(h.flow.model)
    let running = Task { await model.run() }
    try await waitUntil { model.phase == .recording }
    h.flow.checkBattery()
    #expect(h.flow.finishing == nil)
    _ = await model.stop()
    await running.value
  }

  private func waitUntil(_ condition: () -> Bool) async throws {
    for _ in 0..<200 where !condition() {
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(condition())
  }

  private func showSummary(_ night: Night, in h: Harness) throws -> SessionSummaryRoutes {
    h.flow.start()
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start(AppPreferences())
    try root(h.spy, as: BedsideClockScreen.self).rootView.content.routes.finished(night)
    return try root(h.spy, as: SessionSummaryScreen.self).rootView.content.routes
  }
}

/// Launch: a checkpointed night with events comes back as the recording flow
/// at its summary; without one, nothing opens.
struct LaunchRecoveryTests {
  private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  private func coordinator(checkpoint: Night?) -> AppCoordinator {
    let container = Container.test()
    container.checkpointStore.register { FakeRecordingCheckpointStore(checkpoint) }
    container.deviceServices.register {
      DeviceServices(keepScreenOn: { _ in }, openSettings: {}, isCharging: { true }, batteryLevel: { nil })
    }
    return AppCoordinator(container: container)
  }

  @Test func anInterruptedNightIsOffered() async throws {
    let night = Night(
      start: start, end: start.addingTimeInterval(3600),
      events: [NightEvent(start: start.addingTimeInterval(60), duration: 30, intensity: .light)])
    let app = coordinator(checkpoint: night)
    app.start(in: UIWindow())
    await app.recovery?.value
    #expect(app.recording != nil)
  }

  @Test func nothingOpensWithoutOne() async {
    let app = coordinator(checkpoint: nil)
    app.start(in: UIWindow())
    await app.recovery?.value
    #expect(app.recording == nil)
  }
}
