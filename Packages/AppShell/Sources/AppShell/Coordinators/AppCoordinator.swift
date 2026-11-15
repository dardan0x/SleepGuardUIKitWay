import FactoryKit
import SleepDomain
import UIKit

/// Owns the window's content. Later it also chooses between onboarding and
/// the main tabs, owns the recording flow, and handles deep links.
public final class AppCoordinator {
  private let container: Container
  private(set) var mainTabs: MainTabCoordinator?
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

  /// "Start recording" from any screen. The recording flow arrives in F7;
  /// until then the request is only logged.
  func startRecording() {
    Log.app.info("Start recording requested (recording flow arrives in F7)")
  }

  private func seedSampleNightsInDebug() {
    #if DEBUG
    let repository = container.sessionRepository()
    seeding = Task {
      do {
        try await SampleNights.seedIfEmpty(repository)
      } catch {
        Log.storage.error("Seeding sample nights failed: \(error.localizedDescription, privacy: .public)")
      }
    }
    #endif
  }
}
