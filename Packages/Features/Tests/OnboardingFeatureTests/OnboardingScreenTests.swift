import SleepCore
import Testing
@testable import OnboardingFeature

/// The Health page comes only with a Health request, and the microphone is
/// asked through the dependency.
@MainActor
struct OnboardingScreenTests {
  private func screen(health: (@MainActor () async -> Bool)?, microphone: Bool = true) -> OnboardingScreen {
    OnboardingScreen(
      dependencies: OnboardingDependencies(
        microphoneGranted: { false }, requestMicrophone: { microphone }, requestHealth: health),
      routes: OnboardingRoutes(finish: { _, _ in }))
  }

  @Test func healthOnlyWithAHealthRequest() {
    #expect(screen(health: { true }).pages.pages.contains(.health))
    #expect(!screen(health: nil).pages.pages.contains(.health))
  }

  @Test func theMicrophoneIsAskedThroughTheDependency() async {
    var asked = 0
    let screen = OnboardingScreen(
      dependencies: OnboardingDependencies(
        microphoneGranted: { false },
        requestMicrophone: {
          asked += 1
          return false
        },
        requestHealth: nil),
      routes: OnboardingRoutes(finish: { _, _ in }))
    await screen.requestMicrophone()
    #expect(asked == 1)
  }
}
