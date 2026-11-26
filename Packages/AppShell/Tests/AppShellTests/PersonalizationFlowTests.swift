import AppShellTestSupport
import FactoryKit
import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import SleepGuardDesignKit
import SleepStrings
import SwiftUI
import Testing
import UIKit
@testable import AppShell
@testable import ScreenKit
@testable import SessionDetailFeature
@testable import SettingsFeature
@testable import StatisticsFeature

/// The briefing opens after launch once per new night (not when turned off),
/// the dashboard's profile prompt opens the editor and counts dismissals, and
/// a night's report and clips go to the share sheet.
@MainActor
struct PersonalizationFlowTests {
  let start = Date().addingTimeInterval(-30 * 3600)

  func night(_ offsetDays: Double = 0, clip: String? = nil) -> Night {
    let start = start.addingTimeInterval(-offsetDays * 86400)
    return Night(start: start, end: start.addingTimeInterval(7 * 3600), events: [
      NightEvent(start: start.addingTimeInterval(600), duration: 40, intensity: .light, clipFileName: clip),
    ])
  }

  // MARK: - Briefing

  private func launch(briefingEnabled: Bool) async -> FakePreferencesStore {
    let container = Container.test(repository: FakeSessionRepository([night(), night(1)]))
    var preferences = AppPreferences()
    preferences.hasCompletedOnboarding = true
    preferences.briefingEnabled = briefingEnabled
    let store = FakePreferencesStore(preferences)
    container.preferencesStore.register { store }
    let logs = FakeLifestyleLogStore()
    container.lifestyleLogStore.register { logs }
    let app = AppCoordinator(composition: AppComposition(container: container))
    app.start(in: UIWindow())
    await app.launch?.value
    await app.briefing?.value
    return store
  }

  @Test func aNewNightOpensTheBriefingOnce() async {
    #expect(await launch(briefingEnabled: true).load().lastBriefingShown != nil)
  }

  @Test func turnedOffItNeverOpens() async {
    #expect(await launch(briefingEnabled: false).load().lastBriefingShown == nil)
  }

  // MARK: - Profile prompt

  @Test func thePromptOpensTheEditorAndCountsDismissals() async throws {
    let container = Container.test()
    let preferences = FakePreferencesStore()
    container.preferencesStore.register { preferences }
    let spy = NavigatorSpy()
    let flow = AppComposition(container: container).statisticsFlow(navigator: spy, onStartRecording: {})
    flow.start()
    guard case let .setRoot(root) = spy.calls.first, let dashboard = root as? StatisticsViewController else {
      throw Unexpected()
    }
    dashboard.viewModel.routes.openProfile()
    guard case let .present(sheet, _) = spy.calls.last else { throw Unexpected() }
    #expect(sheet is ProfileEditorViewController)
    dashboard.viewModel.routes.dismissProfilePrompt()
    await flow.dismissing?.value
    #expect(await preferences.load().profilePromptDismissCount == 1)
  }

  // MARK: - Sharing

  @Test func theReportGoesToTheShareSheet() async throws {
    let saved = night()
    let container = Container.test(repository: FakeSessionRepository([saved]))
    let spy = NavigatorSpy()
    let navigation = AppComposition(container: container).nightDetail(navigator: spy)
    navigation.shareReport(saved.id)
    await navigation.sharing?.value
    guard case let .present(sheet, _) = spy.calls.last else { throw Unexpected() }
    let activity = try #require(sheet as? UIActivityViewController)
    #expect(activity.isKind(of: UIActivityViewController.self))
  }

  /// A report that can't be made says so, and the button comes back.
  @Test func aFailedReportShowsAnAlertAndFreesTheButton() async throws {
    let spy = NavigatorSpy()
    let navigation = AppComposition(container: Container.test()).nightDetail(navigator: spy)
    let activity = BarItemActivity(label: "")
    navigation.shareReport(UUID(), activity: activity) // no such night
    #expect(activity.isRunning)
    await navigation.sharing?.value
    #expect(!activity.isRunning)
    guard case let .present(alert, .alert) = spy.calls.last else { throw Unexpected() }
    #expect((alert as? UIAlertController)?.title == Strings.reportExportFailedTitle)
  }

  @Test func aClipOnlyGoesWhenItsFileIsThere() throws {
    let container = Container.test()
    let clips = container.storageLocation().clipsDirectory
    try FileManager.default.createDirectory(at: clips, withIntermediateDirectories: true)
    let name = "\(UUID().uuidString).m4a"
    let spy = NavigatorSpy()
    let navigation = AppComposition(container: container).nightDetail(navigator: spy)
    navigation.shareClip(of: night(clip: name).events[0])
    #expect(spy.calls.isEmpty)
    try Data([1]).write(to: clips.appendingPathComponent(name))
    defer { try? FileManager.default.removeItem(at: clips.appendingPathComponent(name)) }
    navigation.shareClip(of: night(clip: name).events[0])
    guard case let .present(sheet, _) = spy.calls.last else { throw Unexpected() }
    #expect(sheet is UIActivityViewController)
  }

  private struct Unexpected: Error {}
}
