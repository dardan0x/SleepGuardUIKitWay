import FactoryKit
import ScreenKit
import SleepAudio
import SleepDomain
import UIKit

/// Owns the window's content and the recording flow. Later it also chooses
/// between onboarding and the main tabs, and handles deep links.
public final class AppCoordinator {
  private let container: Container
  private(set) var mainTabs: MainTabCoordinator?
  /// The night being recorded, from prestart to saved or discarded.
  private(set) var recording: RecordingFlow?
  /// Debug only: fills an empty store with sample nights.
  private var seeding: Task<Void, Never>?

  init(container: Container) {
    self.container = container
  }

  deinit {
    seeding?.cancel()
  }

  public func start(in window: UIWindow) {
    let mainTabs = MainTabCoordinator(container: container, onStartRecording: { [weak self] in self?.startRecording() })
    window.rootViewController = mainTabs.tabBarController
    window.tintColor = UIColor(container.theme().palette.accent)
    window.makeKeyAndVisible()
    self.mainTabs = mainTabs
    seedSampleNightsInDebug()
  }

  /// "Start recording" from any screen: the recording flow, full screen over
  /// the tabs. One at a time.
  func startRecording() {
    guard recording == nil, let tabs = mainTabs?.tabBarController else { return }
    let navigator = NavigationControllerNavigator()
    let height = tabs.view.window?.windowScene?.screen.bounds.height ?? 0
    let flow = RecordingFlow(navigator: navigator, container: container, compactHeight: height <= 874) { [weak self] in
      self?.recording = nil
      tabs.dismiss(animated: true)
    }
    flow.start()
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
