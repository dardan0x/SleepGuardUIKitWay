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
@testable import HistoryFeature
@testable import ScreenKit
@testable import SessionDetailFeature

struct HistoryFlowTests {
  private let night = Night(
    start: Date(timeIntervalSinceReferenceDate: 815_000_000),
    end: Date(timeIntervalSinceReferenceDate: 815_000_000 + 8 * 3600))

  private func makeFlow(_ nights: [Night] = []) -> (HistoryFlow, NavigatorSpy, FakeSessionRepository) {
    let repository = FakeSessionRepository(nights)
    let container = Container.test(repository: repository)
    let spy = NavigatorSpy()
    return (HistoryFlow(navigator: spy, container: container), spy, repository)
  }

  @Test func startShowsTheListTitledSessions() throws {
    let (flow, spy, _) = makeFlow()
    flow.start()
    guard case let .setRoot(root) = try #require(spy.calls.first) else {
      Issue.record("expected setRoot, got \(spy.calls)")
      return
    }
    let list = try #require(root as? HistoryViewController)
    #expect(list.navigationItem.title == Strings.tabSessions)
    #expect(list.navigationItem.largeTitleDisplayMode == .never)
  }

  /// Opening a night pushes its detail, titled with its date, delete in the bar.
  @Test func openingANightPushesItsDetail() throws {
    let (flow, spy, _) = makeFlow([night])
    flow.start()
    let list = try #require(rootList(spy))

    list.routes.openNight(night.summary())

    guard case let .push(pushed) = spy.calls.last else {
      Issue.record("expected push, got \(spy.calls)")
      return
    }
    let detail = try #require(pushed as? SessionDetailViewController)
    #expect(detail.navigationItem.title == night.start.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
    #expect(detail.navigationItem.rightBarButtonItems?.map(\.accessibilityLabel) == [Strings.actionDelete, Strings.a11yExportReport])
  }

  /// The trash button asks first; nothing is deleted until the user confirms.
  @Test func theDeleteButtonAsksForConfirmation() async throws {
    let (flow, spy, repository) = makeFlow([night])
    flow.start()
    try #require(rootList(spy)).routes.openNight(night.summary())
    guard case let .push(pushed) = spy.calls.last else {
      Issue.record("expected push, got \(spy.calls)")
      return
    }
    let trash = try #require(pushed.navigationItem.rightBarButtonItems?.first?.primaryAction)

    trash.performWithSender(nil, target: nil)

    guard case let .present(presented, style) = spy.calls.last else {
      Issue.record("expected present, got \(spy.calls)")
      return
    }
    let alert = try #require(presented as? UIAlertController)
    #expect(style == .alert)
    #expect(alert.title == Strings.sessionDeleteConfirmTitle)
    #expect(alert.actions.map(\.title) == [Strings.actionCancel, Strings.actionDelete])
    #expect(alert.actions.map(\.style) == [.cancel, .destructive])
    #expect(await repository.deletedIDs.isEmpty)
  }

  /// "Show all" presents the rows it was given in a sheet; close dismisses it.
  @Test func showAllPresentsTheEventsSheet() throws {
    let start = night.start
    let events = [
      NightEvent(start: start.addingTimeInterval(600), duration: 60, category: .snoring, intensity: .loud),
      NightEvent(start: start.addingTimeInterval(3600), duration: 10, category: .sleepTalking, intensity: .quiet),
    ]
    let noisy = Night(start: start, end: night.end, events: events)
    let rows = EventListRow.rows(for: noisy)
    let (flow, spy, _) = makeFlow([noisy])
    flow.start()
    try #require(rootList(spy)).routes.openNight(noisy.summary())
    guard case let .push(pushed) = spy.calls.last else {
      Issue.record("expected push, got \(spy.calls)")
      return
    }
    let detail = try #require(pushed as? SessionDetailViewController)

    detail.routes.showAllEvents(rows, noisy.events)

    guard case let .present(presented, style) = spy.calls.last else {
      Issue.record("expected present, got \(spy.calls)")
      return
    }
    #expect(style == .sheet(detents: [.medium, .large]))
    let navigation = try #require(presented as? UINavigationController)
    let sheet = try #require(navigation.viewControllers.first as? EventsSheetViewController)
    #expect(sheet.rows == rows)
    #expect(sheet.navigationItem.title == Strings.recordingsDetailEventsLabel)
    let close = try #require(sheet.navigationItem.rightBarButtonItems?.first)
    #expect(close.accessibilityLabel == Strings.actionClose)

    close.primaryAction?.performWithSender(nil, target: nil)
    #expect(spy.calls.last == .dismiss)
  }

  /// Play presents the player over the detail; close dismisses it.
  @Test func playPresentsThePlayerSheet() throws {
    let start = night.start
    let snore = NightEvent(start: start.addingTimeInterval(600), duration: 60, category: .snoring, intensity: .loud, clipFileName: "a.m4a")
    let noisy = Night(start: start, end: night.end, events: [snore])
    let (flow, spy, _) = makeFlow([noisy])
    flow.start()
    try #require(rootList(spy)).routes.openNight(noisy.summary())
    guard case let .push(pushed) = spy.calls.last else {
      Issue.record("expected push, got \(spy.calls)")
      return
    }
    let detail = try #require(pushed as? SessionDetailViewController)

    detail.routes.playEvents([snore], snore.id)

    guard case let .present(presented, style) = spy.calls.last else {
      Issue.record("expected present, got \(spy.calls)")
      return
    }
    #expect(style == .sheet(detents: [.height(580), .large]))
    let navigation = try #require(presented as? UINavigationController)
    let player = try #require(navigation.viewControllers.first as? PlayerViewController)
    #expect(player.navigationItem.title == Strings.eventPlayerNavigationTitle)
    #expect(player.model.events == [snore])
    player.navigationItem.rightBarButtonItems?.first?.primaryAction?.performWithSender(nil, target: nil)
    #expect(spy.calls.last == .dismiss)
  }

  /// The stages' info button presents the stages sheet; its close dismisses it.
  @Test func stagesInfoPresentsTheStagesSheet() throws {
    let staged = Night(
      start: night.start, end: night.end, sleepStages: [SleepStageSegment(stage: .deep, startOffset: 0, duration: 3600)])
    let (flow, spy, _) = makeFlow([staged])
    flow.start()
    try #require(rootList(spy)).routes.openNight(staged.summary())
    guard case let .push(pushed) = spy.calls.last else {
      Issue.record("expected push, got \(spy.calls)")
      return
    }
    let detail = try #require(pushed as? SessionDetailViewController)
    let stages = try #require(SleepStageBreakdown(segments: staged.sleepStages))

    detail.routes.showStagesInfo(stages)

    guard case let .present(presented, style) = spy.calls.last else {
      Issue.record("expected present, got \(spy.calls)")
      return
    }
    #expect(style == .sheet(detents: [.large]))
    let sheet = try #require(presented as? SleepStagesInfoViewController)
    #expect(sheet.breakdown == stages)
    sheet.close()
    #expect(spy.calls.last == .dismiss)
  }

  /// Health brands read stages through their `HealthAccess`; Lite has none.
  @Test func theStageSourceIsTheBrandsHealth() async throws {
    let segment = SleepStageSegment(stage: .rem, startOffset: 0, duration: 600)
    let withHealth = Container.test(brand: TestBrand(health: FakeHealthAccess(stages: [segment])))
    withHealth.sleepStagePort.reset()
    #expect(try await withHealth.sleepStagePort().stages(from: .now, to: .now) == [segment])
    let without = Container.test()
    without.sleepStagePort.reset()
    #expect(without.sleepStagePort() is NoSleepStages)
  }

  @Test func thePlayerIsTitledByTheKindOfEvent() {
    #expect(SessionDetailComposer.playerTitle(for: .sleepTalking) == Strings.eventPlayerSleepTalkingTitle)
    #expect(SessionDetailComposer.playerTitle(for: .coughing) == Strings.eventPlayerNoiseTitle)
  }

  @Test func deletingANightRemovesItThenPops() async {
    let (flow, spy, repository) = makeFlow([night])
    flow.start()
    await flow.delete(night.id)
    #expect(await repository.deletedIDs == [night.id])
    #expect(spy.calls.last == .pop)
  }

  @Test func aFailedDeleteStaysOnTheDetail() async {
    let (flow, spy, repository) = makeFlow([night])
    flow.start()
    struct Failure: Error {}
    await repository.failNextCall(with: Failure())
    await flow.delete(night.id)
    #expect(spy.calls.last != .pop)
  }

  @Test func theFlowIsNotRetainedByItsScreens() {
    var (flow, _, _): (HistoryFlow?, NavigatorSpy, FakeSessionRepository) = makeFlow([night])
    flow?.start()
    weak var weakFlow = flow
    flow = nil
    #expect(weakFlow == nil)
  }

  private func rootList(_ spy: NavigatorSpy) -> HistoryViewController? {
    guard case let .setRoot(root) = spy.calls.first else { return nil }
    return root as? HistoryViewController
  }
}

extension Container {
  /// A container for flow tests: a test brand and in-memory fakes, no disk.
  static func test(brand: TestBrand = TestBrand(), repository: FakeSessionRepository = FakeSessionRepository()) -> Container {
    let container = Container()
    container.brand.register { brand }
    container.sessionRepository.register { repository }
    container.sessionFileStore.register { FakeSessionFileStore() }
    container.sleepStagePort.register { FakeSleepStagePort() }
    container.makeClipPlayer.register { { FakeClipPlayer() } }
    container.clipWaveformSource.register { FakeClipWaveformSource() }
    container.checkpointStore.register { FakeRecordingCheckpointStore() }
    let preferences = FakePreferencesStore()
    container.preferencesStore.register { preferences }
    let profiles = FakeProfileStore()
    container.profileStore.register { profiles }
    container.makeRawLogWriter.register { { FakeRawLogWriter() } }
    container.makeAudioCapture.register { { FakeAudioCapture() } }
    let logs = FakeLifestyleLogStore()
    container.lifestyleLogStore.register { logs }
    container.makeMelodyPlayer.register { { _ in FakeMelodyPlayer() } }
    container.makeMelodyRecorder.register { { FakeMelodyRecorder() } }
    if brand.configuration.snoreInterrupter {
      container.makeMelodyStore.register { { FakeMelodyStore() } }
    }
    container.deviceServices.register {
      DeviceServices(keepScreenOn: { _ in }, openSettings: {}, isCharging: { true }, batteryLevel: { nil })
    }
    return container
  }
}
