import AppShell
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  private var app: AppCoordinator?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)
    let app = AppShell.bootstrap(brand: appBrand)
    app.start(in: window)
    self.window = window
    self.app = app
    // Launched by a link: opened once the app is ready.
    if let url = connectionOptions.urlContexts.first?.url { app.open(url) }
  }

  /// A link while the app is running.
  func scene(_: UIScene, openURLContexts contexts: Set<UIOpenURLContext>) {
    if let url = contexts.first?.url { app?.open(url) }
  }
}
