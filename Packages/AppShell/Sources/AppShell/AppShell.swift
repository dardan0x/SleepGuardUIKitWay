import FactoryKit
import UIKit

/// The app targets' entry point into the shell.
public enum AppShell {
  /// Registers the brand and returns the coordinator that owns the app's UI.
  /// Call once, from the scene delegate.
  public static func bootstrap(brand: some BrandComposition) -> AppCoordinator {
    let container = Container.shared
    container.brand.register { brand }
    return AppCoordinator(container: container)
  }
}
