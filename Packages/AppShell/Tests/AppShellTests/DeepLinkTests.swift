import AppShellTestSupport
import FactoryKit
import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import Testing
import UIKit
@testable import AppShell
@testable import SessionDetailFeature
@testable import StatisticsFeature

/// Links the app is opened with (F13-T12): what they parse to, and where the
/// app coordinator takes them.
@MainActor
struct DeepLinkTests {
  // MARK: - Parsing

  @Test func linksParseLikeSleepGuardsWidgetLinks() throws {
    let id = UUID()
    #expect(try AppRoute(url: #require(URL(string: "nocturne://start"))) == .startRecording)
    #expect(try AppRoute(url: #require(URL(string: "sleepguardway://session/\(id.uuidString)"))) == .night(id))
    #expect(try AppRoute(url: #require(URL(string: "dawn://last7nights"))) == .lastSevenNights)
  }

  @Test func unknownLinksParseToNothing() throws {
    #expect(try AppRoute(url: #require(URL(string: "dawn://settings"))) == nil)
    #expect(try AppRoute(url: #require(URL(string: "dawn://session/not-an-id"))) == nil)
  }

  // MARK: - Routing

  private let night = Night(
    start: Date(timeIntervalSinceReferenceDate: 815_000_000),
    end: Date(timeIntervalSinceReferenceDate: 815_000_000 + 8 * 3600))

  /// The app with its tabs up and nothing over them.
  private func runningApp(tabs: [AppTab] = [.history, .statistics, .settings]) async -> AppCoordinator {
    let container = Container.test(brand: TestBrand(tabs: tabs), repository: FakeSessionRepository([night]))
    var preferences = AppPreferences()
    preferences.hasCompletedOnboarding = true
    container.preferencesStore.register { FakePreferencesStore(preferences) }
    let app = AppCoordinator(composition: AppComposition(container: container))
    app.start(in: UIWindow())
    await app.launch?.value
    await app.briefing?.value
    return app
  }

  private func navigation(_ app: AppCoordinator, _ tab: AppTab) throws -> UINavigationController {
    let tabs = try #require(app.mainTabs?.tabBarController)
    #expect(try tabs.selectedViewController === tabs.viewControllers?[#require(app.mainTabs?.flows.firstIndex { $0.tab == tab })])
    return try #require(tabs.selectedViewController as? UINavigationController)
  }

  @Test func aNightLinkOpensItsDetailInSessions() async throws {
    let app = await runningApp()
    app.handle(.night(night.id))
    await app.routing?.value
    #expect(try navigation(app, .history).topViewController is SessionDetailViewController)
  }

  @Test func withoutSessionsANightOpensInStatistics() async throws {
    let app = await runningApp(tabs: [.statistics, .settings])
    app.handle(.night(night.id))
    await app.routing?.value
    #expect(try navigation(app, .statistics).topViewController is SessionDetailViewController)
  }

  @Test func aLinkToANightThatIsGoneChangesNothing() async throws {
    let app = await runningApp()
    app.handle(.night(UUID()))
    await app.routing?.value
    let tabs = try #require(app.mainTabs?.tabBarController)
    #expect(tabs.selectedIndex == 0)
    #expect((tabs.selectedViewController as? UINavigationController)?.viewControllers.count == 1)
  }

  @Test func lastSevenNightsOpensFromStatistics() async throws {
    let app = await runningApp()
    app.handle(.lastSevenNights)
    let stack = try navigation(app, .statistics).viewControllers
    #expect(stack.count == 2)
    #expect(stack.last is LastSevenNightsViewController)
  }

  @Test func startOpensTheRecordingFlow() async {
    let app = await runningApp()
    app.handle(.startRecording)
    #expect(app.recording != nil)
  }

  /// While a night records, a link waits; "start" has nothing to start.
  @Test func whileRecordingLinksWaitAndStartIsDropped() async {
    let app = await runningApp()
    app.startRecording()
    app.handle(.startRecording)
    #expect(app.pendingRoute == nil)
    app.handle(.lastSevenNights)
    #expect(app.pendingRoute == .lastSevenNights)
  }

  /// Before the tabs (launching, the onboarding), a link waits for them.
  @Test func beforeTheTabsALinkWaits() {
    let app = AppCoordinator(composition: AppComposition(container: Container.test()))
    app.handle(.night(night.id))
    #expect(app.pendingRoute == .night(night.id))
  }
}
