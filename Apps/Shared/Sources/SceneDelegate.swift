import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)
    // Replaced by AppShell.bootstrap(brand:) in F1-T6.
    window.rootViewController = PlaceholderViewController()
    window.makeKeyAndVisible()
    self.window = window
  }
}
