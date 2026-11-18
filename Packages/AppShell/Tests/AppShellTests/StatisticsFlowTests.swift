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
@testable import ScreenKit
@testable import SessionDetailFeature
@testable import StatisticsFeature

/// The Statistics tab: dashboard root, pushes, opening a night, start recording.
struct StatisticsFlowTests {
  private let night = NightSummary(
    id: UUID(), start: Date(timeIntervalSinceReferenceDate: 815_000_000),
    end: Date(timeIntervalSinceReferenceDate: 815_000_000 + 8 * 3600), score: 80, snoringDuration: 0, eventCount: 0)

  private func makeFlow(onStartRecording: @escaping @MainActor () -> Void = {}) -> (StatisticsFlow, NavigatorSpy) {
    let spy = NavigatorSpy()
    return (StatisticsFlow(navigator: spy, container: .test(), onStartRecording: onStartRecording), spy)
  }

  private func dashboard(_ spy: NavigatorSpy) throws -> StatisticsViewController {
    guard case let .setRoot(root) = try #require(spy.calls.first) else { throw Failure.noRoot }
    return try #require(root as? StatisticsViewController)
  }

  private func lastPushed(_ spy: NavigatorSpy) throws -> UIViewController {
    guard case let .push(pushed) = try #require(spy.calls.last) else { throw Failure.noPush }
    return pushed
  }

  enum Failure: Error { case noRoot, noPush }

  @Test func startShowsTheDashboardWithTheCalendarButton() throws {
    let (flow, spy) = makeFlow()
    flow.start()
    let root = try dashboard(spy)
    #expect(root.navigationItem.title == Strings.tabStatistics)
    #expect(root.navigationItem.largeTitleDisplayMode == .always)
    #expect(root.navigationItem.rightBarButtonItems?.map(\.accessibilityLabel) == [Strings.watchCalendar])
  }

  @Test func theCalendarButtonPushesTheCalendar() throws {
    let (flow, spy) = makeFlow()
    flow.start()
    try dashboard(spy).navigationItem.rightBarButtonItems?.first?.primaryAction?.performWithSender(nil, target: nil)
    let calendar = try #require(try lastPushed(spy) as? CalendarViewController)
    #expect(calendar.navigationItem.title == Strings.watchCalendar)
  }

  @Test func routesPushTrendsAndLastSevenNights() throws {
    let (flow, spy) = makeFlow()
    flow.start()
    let routes = try dashboard(spy).viewModel.routes
    routes.showTrends()
    #expect(try (lastPushed(spy) as? TrendsViewController)?.navigationItem.title == Strings.statsTrendsTitle)
    routes.showLastSevenNights()
    #expect(try (lastPushed(spy) as? LastSevenNightsViewController)?.navigationItem.title == Strings.statsTrendsLastSevenNights)
  }

  @Test func aNightFromLastSevenNightsOrTheCalendarOpensItsDetail() throws {
    let (flow, spy) = makeFlow()
    flow.start()
    try dashboard(spy).viewModel.routes.showLastSevenNights()
    let list = try #require(try lastPushed(spy) as? LastSevenNightsViewController)
    list.viewModel.routes?.openNight(night)
    #expect(try lastPushed(spy) is SessionDetailViewController)

    try dashboard(spy).navigationItem.rightBarButtonItems?.first?.primaryAction?.performWithSender(nil, target: nil)
    let calendar = try #require(try lastPushed(spy) as? CalendarViewController)
    calendar.viewModel.routes?.openNight(night)
    let detail = try #require(try lastPushed(spy) as? SessionDetailViewController)
    #expect(detail.navigationItem.rightBarButtonItems?.map(\.accessibilityLabel) == [Strings.actionDelete, Strings.a11yExportReport])
  }

  @Test func stagesInfoPresentsTheStagesSheet() throws {
    let (flow, spy) = makeFlow()
    flow.start()
    let stages = try #require(SleepStageBreakdown(segments: [SleepStageSegment(stage: .light, startOffset: 0, duration: 600)]))
    try dashboard(spy).viewModel.routes.showStagesInfo(stages)
    guard case let .present(presented, style) = try #require(spy.calls.last) else { throw Failure.noRoot }
    #expect(style == .sheet(detents: [.large]))
    #expect((presented as? SleepStagesInfoViewController)?.breakdown == stages)
  }

  @Test func startRecordingGoesToTheAppCoordinator() throws {
    var requests = 0
    let (flow, spy) = makeFlow { requests += 1 }
    flow.start()
    try dashboard(spy).viewModel.routes.startRecording()
    #expect(requests == 1)
    #expect(spy.calls.count == 1) // nothing pushed or presented by the tab
  }

  @Test func theFlowIsNotRetainedByItsScreens() throws {
    var flow: StatisticsFlow? = makeFlow().0
    flow?.start()
    weak var weakFlow = flow
    flow = nil
    #expect(weakFlow == nil)
  }
}
