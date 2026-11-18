import FactoryKit
import OnboardingFeature
import ScreenKit
import UIKit

/// Builds the onboarding: its dependencies (the microphone, and Apple Health
/// in a brand that has it), then its view model, then the screen (ADR 0008).
/// No bar: the pages draw their own buttons.
struct OnboardingFactory {
  let container: Container

  func make(routes: OnboardingRoutes) -> UIViewController {
    let capture = container.makeAudioCapture()()
    let device = container.deviceServices()
    var requestHealth: (@MainActor () async -> Bool)?
    if let health = container.healthAccess() {
      requestHealth = { await health.requestAuthorization() }
    }
    let dependencies = OnboardingDependencies(
      microphoneGranted: { device.microphone() == .granted },
      requestMicrophone: { await capture.requestPermission() },
      requestHealth: requestHealth)
    return OnboardingViewController(
      viewModel: OnboardingViewModel(dependencies: dependencies, routes: routes),
      theme: container.theme(),
      chrome: ScreenChrome(hidesNavigationBar: true))
  }
}
