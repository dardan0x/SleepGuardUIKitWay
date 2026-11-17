import FactoryKit
import OnboardingFeature
import ScreenKit
import SettingsFeature
import SleepDomain
import UIKit

/// First launch: the onboarding pages, then the app. Finishing keeps
/// `hasCompletedOnboarding` (so it shows once) and, when Health was allowed
/// here, turns on Sync to Apple Health (SleepGuard does the same), then hands
/// back whether the person chose "Start recording".
final class OnboardingFlow {
  private let navigator: any Navigator
  private let container: Container
  private let onFinish: @MainActor (_ startRecording: Bool) -> Void
  /// Saving the choices, awaited by tests.
  private(set) var finishing: Task<Void, Never>?

  init(navigator: any Navigator, container: Container, onFinish: @escaping @MainActor (_ startRecording: Bool) -> Void) {
    self.navigator = navigator
    self.container = container
    self.onFinish = onFinish
  }

  func start() {
    let capture = container.makeAudioCapture()()
    let device = container.deviceServices()
    var requestHealth: (@MainActor () async -> Bool)?
    if let health = container.healthAccess() {
      requestHealth = { await health.requestAuthorization() }
    }
    let screen = OnboardingScreen(
      dependencies: OnboardingDependencies(
        microphoneGranted: { device.microphone() == .granted },
        requestMicrophone: { await capture.requestPermission() },
        requestHealth: requestHealth),
      routes: OnboardingRoutes(finish: { [weak self] healthGranted, startRecording in
        self?.finish(healthGranted: healthGranted, startRecording: startRecording)
      }))
    navigator.setRoot(HostingScreen(rootView: screen, theme: container.theme(), chrome: ScreenChrome(hidesNavigationBar: true)))
  }

  /// What the screen's finish route does; internal for tests.
  func finish(healthGranted: Bool, startRecording: Bool) {
    guard finishing == nil else { return }
    let store = container.preferencesStore()
    finishing = Task { [onFinish] in
      var preferences = await store.load()
      preferences.hasCompletedOnboarding = true
      if healthGranted { preferences.syncToHealth = true }
      await store.save(preferences)
      onFinish(startRecording)
    }
  }
}
