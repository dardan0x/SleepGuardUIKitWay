import AppShellTestSupport
import FactoryKit
import Foundation
import SleepCore
import SleepDomain
import SleepDomainTestSupport
import SwiftUI
import Testing
import UIKit
@testable import AppShell
@testable import OnboardingFeature
@testable import ScreenKit

/// The onboarding: shown on first launch only, a Health page only in a brand
/// with Health, and finishing keeps the flag, turns on Health sync when
/// allowed, and can go straight to a night.
@MainActor
struct OnboardingFlowTests {
  private struct Harness {
    let flow: OnboardingFlow
    let spy: NavigatorSpy
    /// Read directly: the container's singleton cache is shared between tests.
    let preferences: FakePreferencesStore
    let finished: () -> [Bool]
  }

  private func makeFlow(health: (any HealthAccess)? = nil) -> Harness {
    let container = Container.test(brand: TestBrand(health: health))
    let preferences = FakePreferencesStore()
    container.preferencesStore.register { preferences }
    let spy = NavigatorSpy()
    var finished: [Bool] = []
    let flow = OnboardingFlow(navigator: spy, container: container) { finished.append($0) }
    flow.start()
    return Harness(flow: flow, spy: spy, preferences: preferences, finished: { finished })
  }

  private func screen(_ h: Harness) throws -> OnboardingViewController {
    guard case let .setRoot(controller) = h.spy.calls.first,
          let screen = controller as? OnboardingViewController else { throw Unexpected() }
    return screen
  }

  private struct Unexpected: Error {}

  @Test func aHealthBrandAsksForHealthAndLiteDoesNot() throws {
    #expect(try screen(makeFlow(health: FakeHealthAccess(granted: true))).pages.pages.contains(.health))
    #expect(try !screen(makeFlow()).pages.pages.contains(.health))
  }

  @Test func finishingKeepsTheFlagAndHandsBackTheChoice() async throws {
    let h = makeFlow()
    try screen(h).routes.finish(false, true)
    await h.flow.finishing?.value
    let stored = await h.preferences.load()
    #expect(stored.hasCompletedOnboarding)
    #expect(!stored.syncToHealth)
    #expect(h.finished() == [true])
  }

  @Test func healthAllowedHereTurnsOnSync() async throws {
    let h = makeFlow(health: FakeHealthAccess(granted: true))
    try screen(h).routes.finish(true, false)
    await h.flow.finishing?.value
    #expect(await h.preferences.load().syncToHealth)
    #expect(h.finished() == [false])
  }

  @Test func finishingTwiceSavesOnce() async throws {
    let h = makeFlow()
    let routes = try screen(h).routes
    routes.finish(false, false)
    routes.finish(false, true)
    await h.flow.finishing?.value
    #expect(h.finished() == [false])
  }
}

/// First launch shows the onboarding; afterwards the tabs come straight up,
/// and a "Start recording" from the onboarding opens a night over them.
@MainActor
struct FirstLaunchTests {
  private func app(onboarded: Bool) -> (AppCoordinator, FakePreferencesStore) {
    let container = Container.test()
    var preferences = AppPreferences()
    preferences.hasCompletedOnboarding = onboarded
    let store = FakePreferencesStore(preferences)
    container.preferencesStore.register { store }
    return (AppCoordinator(container: container), store)
  }

  @Test func firstLaunchShowsTheOnboardingAndNothingElse() async {
    let (app, _) = app(onboarded: false)
    app.start(in: UIWindow())
    await app.launch?.value
    #expect(app.onboarding != nil)
    #expect(app.mainTabs == nil)
    #expect(app.recovery == nil)
  }

  @Test func laterLaunchesShowTheTabs() async {
    let (app, _) = app(onboarded: true)
    app.start(in: UIWindow())
    await app.launch?.value
    #expect(app.onboarding == nil)
    #expect(app.mainTabs != nil)
  }

  @Test func finishingTheOnboardingShowsTheTabs() async throws {
    let (app, _) = app(onboarded: false)
    app.start(in: UIWindow())
    await app.launch?.value
    let flow = try #require(app.onboarding)
    flow.finish(healthGranted: false, startRecording: false)
    await flow.finishing?.value
    #expect(app.onboarding == nil)
    #expect(app.mainTabs != nil)
  }
}
