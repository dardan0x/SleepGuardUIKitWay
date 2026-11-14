import ScreenKit
import Testing
import UIKit

/// Presenting and dismissing for real. These run inside the SleepGuard app,
/// because UIKit only finishes a presentation in a window that belongs to a
/// scene, and package tests have none. Each wait is driven by the presented
/// controller's own appearance callbacks, not by polling.
@MainActor
struct NavigatorInAppTests {
  @Test func presentsAndDismissesASheet() async throws {
    let (navigator, window) = try navigatorInAppWindow()
    defer { window.isHidden = true }
    let sheet = AppearanceProbe()

    await sheet.appears { navigator.present(sheet, style: .sheet(detents: [.medium, .large])) }
    #expect(navigator.navigationController.presentedViewController === sheet)

    await sheet.disappears { navigator.dismiss() }
    #expect(navigator.navigationController.presentedViewController == nil)
  }

  /// The second present is issued while the first is still in flight. It must
  /// wait and then present above it, not be dropped.
  @Test func presentDuringAnotherPresentationWaitsAndStacks() async throws {
    let (navigator, window) = try navigatorInAppWindow()
    defer { window.isHidden = true }
    let fullScreen = AppearanceProbe()
    let sheet = AppearanceProbe()

    await sheet.appears {
      navigator.present(fullScreen, style: .fullScreen)
      navigator.present(sheet, style: .sheet(detents: [.large]))
    }
    #expect(navigator.navigationController.presentedViewController === fullScreen)
    #expect(fullScreen.presentedViewController === sheet)

    await sheet.disappears { navigator.dismiss() }
    #expect(fullScreen.presentedViewController == nil)
    #expect(navigator.navigationController.presentedViewController === fullScreen)
  }

  private func navigatorInAppWindow() throws -> (NavigationControllerNavigator, UIWindow) {
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let navigator = NavigationControllerNavigator(animated: false)
    navigator.setRoot(UIViewController())
    let window = UIWindow(windowScene: scene)
    window.rootViewController = navigator.navigationController
    window.makeKeyAndVisible()
    return (navigator, window)
  }
}

/// Resumes a waiting test when UIKit reports it on or off screen.
private final class AppearanceProbe: UIViewController {
  private var onAppear: (() -> Void)?
  private var onDisappear: (() -> Void)?

  func appears(after action: () -> Void) async {
    await withCheckedContinuation { continuation in
      onAppear = { continuation.resume() }
      action()
    }
  }

  func disappears(after action: () -> Void) async {
    await withCheckedContinuation { continuation in
      onDisappear = { continuation.resume() }
      action()
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    onAppear?()
    onAppear = nil
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    onDisappear?()
    onDisappear = nil
  }
}
