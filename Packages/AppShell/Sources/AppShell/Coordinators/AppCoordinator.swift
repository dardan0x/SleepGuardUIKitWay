import FactoryKit
import ScreenKit
import SleepAudio
import SleepDomain
import UIKit

/// Owns the window's content: the onboarding on first launch, then the main
/// tabs, and the recording flow over them. Later it also handles deep links.
public final class AppCoordinator {
  private let container: Container
  private weak var window: UIWindow?
  /// Reads the preferences, then shows the onboarding or the tabs; awaited by tests.
  private(set) var launch: Task<Void, Never>?
  private(set) var onboarding: OnboardingFlow?
  private(set) var mainTabs: MainTabCoordinator?
  /// The night being recorded, from prestart to saved or discarded.
  private(set) var recording: RecordingFlow?
  /// Debug only: fills an empty store with sample nights.
  private var seeding: Task<Void, Never>?
  /// Looks for a night the app didn't get to finish; internal for tests.
  private(set) var recovery: Task<Void, Never>?
  /// Resolved at launch, used once the tabs are up.
  private let recoverInterruptedSession: RecoverInterruptedSession
  private let enforceStorageLimits: EnforceStorageLimits

  init(container: Container) {
    self.container = container
    recoverInterruptedSession = container.recoverInterruptedSession()
    enforceStorageLimits = container.enforceStorageLimits()
  }

  deinit {
    seeding?.cancel()
    recovery?.cancel()
  }

  /// The theme's background until the preferences say what comes first, so
  /// the tabs never flash before the onboarding.
  public func start(in window: UIWindow) {
    self.window = window
    let placeholder = UIViewController()
    placeholder.view.backgroundColor = UIColor(container.theme().palette.bgPrimary)
    window.rootViewController = placeholder
    window.tintColor = UIColor(container.theme().palette.accent)
    window.makeKeyAndVisible()
    let preferences = container.preferencesStore()
    launch = Task { [weak self] in
      let completed = await preferences.load().hasCompletedOnboarding
      if completed {
        self?.showTabs()
      } else {
        self?.showOnboarding()
      }
    }
  }

  private func showOnboarding() {
    let navigator = NavigationControllerNavigator()
    let flow = OnboardingFlow(navigator: navigator, container: container) { [weak self] startRecording in
      self?.onboarding = nil
      self?.showTabs()
      if startRecording { self?.startRecording() }
    }
    flow.start()
    onboarding = flow
    window?.rootViewController = navigator.navigationController
  }

  /// The app proper. A night left unfinished and the Debug sample nights wait
  /// for it: nothing runs over the onboarding.
  private func showTabs() {
    let mainTabs = MainTabCoordinator(container: container, onStartRecording: { [weak self] in self?.startRecording() })
    window?.rootViewController = mainTabs.tabBarController
    self.mainTabs = mainTabs
    offerInterruptedNight()
    seedSampleNightsInDebug()
  }

  /// "Start recording" from any screen: the recording flow, full screen over
  /// the tabs. One at a time.
  func startRecording() {
    presentRecording { $0.start() }
  }

  /// A night interrupted by a crash, a kill or a dead battery comes back as
  /// its summary, for Save or Discard (SleepGuard does the same at launch).
  /// Then the storage limits, as SleepGuard runs them at launch. An offered
  /// night keeps its checkpoint until saved or discarded, so its files stay.
  private func offerInterruptedNight() {
    let recover = recoverInterruptedSession
    let enforceLimits = enforceStorageLimits
    recovery = Task { [weak self] in
      if let night = await recover() {
        Log.app.notice("Offering a night interrupted before it was saved")
        self?.presentRecording { $0.start(recovering: night) }
      }
      do {
        try await enforceLimits()
      } catch {
        Log.storage.error("Storage limits failed at launch: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  private func presentRecording(_ begin: (RecordingFlow) -> Void) {
    guard recording == nil, let tabs = mainTabs?.tabBarController else { return }
    let navigator = NavigationControllerNavigator()
    let height = tabs.view.window?.windowScene?.screen.bounds.height ?? 0
    let flow = RecordingFlow(navigator: navigator, container: container, compactHeight: height <= 874) { [weak self] in
      self?.recording = nil
      tabs.dismiss(animated: true)
    }
    begin(flow)
    recording = flow
    navigator.navigationController.modalPresentationStyle = .fullScreen
    tabs.present(navigator.navigationController, animated: true)
  }

  private func seedSampleNightsInDebug() {
    #if DEBUG
    let repository = container.sessionRepository()
    let clips = container.storageLocation().clipsDirectory
    seeding = Task {
      do {
        try await SampleNights.seedIfEmpty(repository) { name, seconds, intensity in
          try SleepAudio.writeSampleClip(to: clips.appendingPathComponent(name), seconds: seconds, intensity: intensity)
        }
      } catch {
        Log.storage.error("Seeding sample nights failed: \(error.localizedDescription, privacy: .public)")
      }
    }
    #endif
  }
}
