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
  }

  private struct Harness {
    let flow: RecordingFlow
    let spy: NavigatorSpy
    let repository: FakeSessionRepository
    let files: FakeSessionFileStore
    let device: DeviceLog
    let closed: () -> Int
  }

  private func makeFlow() -> Harness {
    let repository = FakeSessionRepository()
    let files = FakeSessionFileStore()
    let device = DeviceLog()
    let container = Container.test(repository: repository)
    container.sessionFileStore.register { files }
    container.makeAudioCapture.register { { FakeAudioCapture() } }
    container.deviceServices.register {
      DeviceServices(
        keepScreenOn: { device.screenOn.append($0) },
        openSettings: { device.settingsOpened += 1 },
        isCharging: { true })
    }
    let spy = NavigatorSpy()
    var closes = 0
    let flow = RecordingFlow(navigator: spy, container: container, compactHeight: false) { closes += 1 }
    return Harness(flow: flow, spy: spy, repository: repository, files: files, device: device, closed: { closes })
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
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start()
    _ = try root(h.spy, as: BedsideClockScreen.self)
    #expect(h.flow.model != nil)
    #expect(h.device.screenOn == [true])
  }

  @Test func aFinishedNightShowsItsSummaryAndLetsTheScreenSleep() throws {
    let h = makeFlow()
    h.flow.start()
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start()
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
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start()
    try root(h.spy, as: BedsideClockScreen.self).rootView.content.routes.discarded(night(minutes: 1, clips: ["a.caf"]))
    await h.flow.finishing?.value
    #expect(await h.files.removed == ["a.caf"])
    #expect(h.device.screenOn == [true, false])
    #expect(h.closed() == 1)
  }

  @Test func aStartThatFailedClosesWithNothingToRemove() async throws {
    let h = makeFlow()
    h.flow.start()
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start()
    try root(h.spy, as: BedsideClockScreen.self).rootView.content.routes.discarded(nil)
    #expect(h.flow.finishing == nil)
    #expect(await h.files.removed.isEmpty)
    #expect(h.closed() == 1)
  }

  private func showSummary(_ night: Night, in h: Harness) throws -> SessionSummaryRoutes {
    h.flow.start()
    try root(h.spy, as: RecordingPrestartScreen.self).rootView.content.routes.start()
    try root(h.spy, as: BedsideClockScreen.self).rootView.content.routes.finished(night)
    return try root(h.spy, as: SessionSummaryScreen.self).rootView.content.routes
  }
}
