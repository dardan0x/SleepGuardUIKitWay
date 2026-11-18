import SleepCore
import SleepGuardDesignKit
import Testing
@testable import OnboardingFeature
@testable import ScreenKit

/// The Health page comes only with a Health request; the microphone is asked
/// through the dependency; Skip, Back and a permission move between pages.
@MainActor
struct OnboardingViewControllerTests {
  private func screen(
    health: (@MainActor () async -> Bool)?, microphone: @escaping @MainActor () async -> Bool = { true },
    finish: @escaping @MainActor (Bool, Bool) -> Void = { _, _ in }) -> OnboardingViewController
  {
    let screen = OnboardingViewController(
      dependencies: OnboardingDependencies(
        microphoneGranted: { false }, requestMicrophone: microphone, requestHealth: health),
      routes: OnboardingRoutes(finish: finish),
      theme: .sleepGuard, chrome: ScreenChrome(hidesNavigationBar: true))
    screen.loadViewIfNeeded()
    return screen
  }

  @Test func healthOnlyWithAHealthRequest() {
    #expect(screen(health: { true }).pages.pages.contains(.health))
    #expect(!screen(health: nil).pages.pages.contains(.health))
  }

  @Test func startsOnTheFirstPage() {
    let screen = screen(health: nil)
    #expect(screen.page == screen.pages.first)
  }

  @Test func theMicrophoneIsAskedThroughTheDependency() async {
    var asked = 0
    let screen = screen(health: nil, microphone: {
      asked += 1
      return false
    })
    await screen.requestMicrophone()
    #expect(asked == 1)
    #expect(screen.microphone == .notAsked)
  }

  /// Denied moves on at once, to the page after the microphone's.
  @Test func aDeniedPermissionMovesOn() async {
    let screen = screen(health: nil, microphone: { false })
    screen.move(to: .microphone)
    await screen.requestMicrophone()
    #expect(screen.page == screen.pages.next(after: .microphone))
  }

  @Test func movingForwardAndBack() {
    let screen = screen(health: { true })
    screen.move(to: screen.pages.last)
    #expect(screen.page == screen.pages.last)
    screen.move(to: screen.pages.previous(before: screen.page))
    #expect(screen.page == screen.pages.previous(before: screen.pages.last))
  }
}
