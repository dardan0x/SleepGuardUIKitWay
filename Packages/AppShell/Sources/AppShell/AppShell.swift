import UIKit

/// The app targets' entry point into the shell.
public enum AppShell {
  /// The coordinator `bootstrap` made, for the in-app tests to reach the
  /// running app's composition. Nothing in the app reads it.
  @MainActor public private(set) weak static var launched: AppCoordinator?

  /// Builds the brand's composition and returns the coordinator that owns the
  /// app's UI. Call once, from the scene delegate.
  @MainActor
  public static func bootstrap(brand: some BrandComposition) -> AppCoordinator {
    let coordinator = AppCoordinator(composition: AppComposition(brand: brand))
    launched = coordinator
    return coordinator
  }
}
