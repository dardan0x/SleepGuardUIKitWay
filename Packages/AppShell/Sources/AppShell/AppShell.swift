import UIKit

/// Entry point the app targets call. Becomes `bootstrap(brand:)` in F1-T6.
public enum AppShell {
  public static func makeRootViewController() -> UIViewController {
    PlaceholderViewController()
  }
}
