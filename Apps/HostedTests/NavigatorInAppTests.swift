import ScreenKit
import Testing
import UIKit

/// Presenting and dismissing for real. These run inside the SleepGuard app,
/// because UIKit only finishes a presentation in a window that belongs to a
/// scene, and package tests have none. Each wait is driven by the presented
/// controller's own appearance callbacks, not by polling.
/// Each waits on UIKit's appearance callbacks; a regression would wait
/// forever, so the suite has a time limit.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct NavigatorInAppTests {
  @Test func presentsAndDismissesASheet() async throws {
    let (navigator, window) = try navigatorInAppWindow()
    defer { window.isHidden = true }
    let sheet = AppearanceProbe()

    await sheet.appears { navigator.present(sheet, style: .sheet(detents: [.medium, .large])) }
    #expect(navigator.navigationController.presentedViewController === sheet)

    await sheet.disappears { navigator.dismiss(sheet) }
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

    await sheet.disappears { navigator.dismiss(sheet) }
    #expect(fullScreen.presentedViewController == nil)
    #expect(navigator.navigationController.presentedViewController === fullScreen)
  }

  /// The review's case: an alert is up over a sheet and the flow closes the
  /// sheet. Dismissing "the topmost" used to take the alert and leave the
  /// sheet; a targeted dismiss takes the sheet and the alert with it.
  @Test func dismissingASheetTakesTheAlertOverItToo() async throws {
    let (navigator, window) = try navigatorInAppWindow()
    defer { window.isHidden = true }
    let sheet = AppearanceProbe()
    await sheet.appears { navigator.present(sheet, style: .sheet(detents: [.large])) }
    let alert = UIAlertController(title: "", message: nil, preferredStyle: .alert)
    await withCheckedContinuation { done in sheet.present(alert, animated: false) { done.resume() } }
    #expect(sheet.presentedViewController === alert)

    await sheet.disappears { navigator.dismiss(sheet) }

    #expect(navigator.navigationController.presentedViewController == nil)
  }

  /// Present, dismiss, present, all in one turn and animated: the dismiss
  /// waits for its sheet to be up, and the second sheet lands on what stays,
  /// not on the sheet that is closing (which would drop it).
  @Test func presentDismissPresentInOneTurnEndsWithTheSecondSheet() async throws {
    let (navigator, window) = try navigatorInAppWindow(animated: true)
    defer { window.isHidden = true }
    let closing = AppearanceProbe()
    let next = AppearanceProbe()

    await next.appears {
      navigator.present(closing, style: .sheet(detents: [.large]))
      navigator.dismiss(closing)
      navigator.present(next, style: .sheet(detents: [.large]))
    }

    #expect(navigator.navigationController.presentedViewController === next)
    #expect(closing.presentingViewController == nil)
    await next.disappears { navigator.dismiss(next) }
  }

  private func navigatorInAppWindow(animated: Bool = false) throws -> (NavigationControllerNavigator, UIWindow) {
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let navigator = NavigationControllerNavigator(animated: animated)
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

  /// Ends early when the test is cancelled (its time limit), so a
  /// regression fails instead of hanging.
  func appears(after action: () -> Void) async {
    await withTaskCancellationHandler {
      await withCheckedContinuation { continuation in
        onAppear = { continuation.resume() }
        action()
      }
    } onCancel: {
      Task { @MainActor [weak self] in
        self?.onAppear?()
        self?.onAppear = nil
      }
    }
  }

  func disappears(after action: () -> Void) async {
    await withTaskCancellationHandler {
      await withCheckedContinuation { continuation in
        onDisappear = { continuation.resume() }
        action()
      }
    } onCancel: {
      Task { @MainActor [weak self] in
        self?.onDisappear?()
        self?.onDisappear = nil
      }
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
