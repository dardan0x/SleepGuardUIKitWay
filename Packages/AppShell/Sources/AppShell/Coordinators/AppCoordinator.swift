import FactoryKit
import UIKit

/// Owns the window's content. Later it also chooses between onboarding and
/// the main tabs, owns the recording flow, and handles deep links.
public final class AppCoordinator {
  private let container: Container
  private(set) var mainTabs: MainTabCoordinator?

  init(container: Container) {
    self.container = container
  }

  public func start(in window: UIWindow) {
    let mainTabs = MainTabCoordinator(container: container)
    window.rootViewController = mainTabs.tabBarController
    window.tintColor = UIColor(container.theme().palette.accent)
    window.makeKeyAndVisible()
    self.mainTabs = mainTabs
  }
}
