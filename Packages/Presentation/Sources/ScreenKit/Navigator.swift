import UIKit

/// The navigation operations a coordinator performs. Coordinators depend on
/// this protocol, so tests drive them with a spy instead of UIKit.
public protocol Navigator: AnyObject {
  func setRoot(_ controller: UIViewController)
  func push(_ controller: UIViewController)
  func pop()
  func popToRoot()
  func present(_ controller: UIViewController, style: PresentationStyle)
  /// Dismisses `controller` and anything it presented (an alert over a
  /// sheet goes with the sheet). Nothing when it isn't presented.
  func dismiss(_ controller: UIViewController)
}

public extension Navigator {
  /// Presents what `make` builds, handing it a `close` that dismisses
  /// exactly that controller, never whatever else happens to be on top.
  func present(style: PresentationStyle, _ make: (_ close: @escaping @MainActor () -> Void) -> UIViewController) {
    let presented = WeakController()
    let controller = make { [weak self] in
      guard let controller = presented.value else { return }
      self?.dismiss(controller)
    }
    presented.value = controller
    present(controller, style: style)
  }
}

private final class WeakController {
  weak var value: UIViewController?
}

public enum PresentationStyle: Equatable {
  case sheet(detents: [SheetDetent])
  case fullScreen
  /// A `UIAlertController`, which sets its own style.
  case alert
}

public enum SheetDetent: Equatable {
  case medium
  case large
  /// A fixed height in points.
  case height(CGFloat)
}

/// `Navigator` over one `UINavigationController` (one per tab or flow).
///
/// UIKit misbehaves if you push or present while a transition is running
/// (warnings, a lost presentation, a stuck stack). So operations run one at a
/// time, in the order they were asked for: each waits until nothing is
/// moving, does its UIKit call, and the next starts once that has settled.
/// Nothing is dropped, and each operation looks at the screen as it is when
/// it runs: a presentation picks its presenter then (never a sheet that was
/// on its way out), and a dismiss asked for right after a present waits for
/// that present.
public final class NavigationControllerNavigator: Navigator {
  public let navigationController: UINavigationController
  private let animated: Bool
  private var queue: [(_ done: @escaping () -> Void) -> Void] = []
  private var isRunning = false

  /// `animated: false` is for tests.
  public init(navigationController: UINavigationController = UINavigationController(), animated: Bool = true) {
    self.navigationController = navigationController
    self.animated = animated
  }

  public func setRoot(_ controller: UIViewController) {
    perform { [animated] navigation, _ in
      navigation.setViewControllers([controller], animated: animated)
      return navigation
    }
  }

  public func push(_ controller: UIViewController) {
    perform { [animated] navigation, _ in
      navigation.pushViewController(controller, animated: animated)
      return navigation
    }
  }

  public func pop() {
    perform { [animated] navigation, _ in
      navigation.popViewController(animated: animated)
      return navigation
    }
  }

  public func popToRoot() {
    perform { [animated] navigation, _ in
      navigation.popToRootViewController(animated: animated)
      return navigation
    }
  }

  public func present(_ controller: UIViewController, style: PresentationStyle) {
    configure(controller, for: style)
    perform { [animated] _, top in
      top.present(controller, animated: animated)
      return top
    }
  }

  public func dismiss(_ controller: UIViewController) {
    perform { [animated] _, _ in
      // Asked of the presenter: asked of `controller`, UIKit would dismiss
      // what `controller` presented (an alert) and leave it up.
      guard !controller.isBeingDismissed, let presenter = controller.presentingViewController else { return nil }
      presenter.dismiss(animated: animated)
      return presenter
    }
  }

  /// Internal so tests can check it without presenting (package tests have no
  /// scene, so UIKit never finishes a presentation there).
  func configure(_ controller: UIViewController, for style: PresentationStyle) {
    switch style {
    case let .sheet(detents):
      controller.modalPresentationStyle = .pageSheet
      if let sheet = controller.sheetPresentationController {
        sheet.detents = detents.map { detent in
          switch detent {
          case .medium: .medium()
          case .large: .large()
          case let .height(points): .custom { _ in points }
          }
        }
        sheet.prefersGrabberVisible = detents.count > 1
      }
    case .fullScreen:
      controller.modalPresentationStyle = .fullScreen
    case .alert:
      break
    }
  }

  // MARK: - Private

  /// Queues `operation`. It runs when the operations before it have settled
  /// and nothing is moving; it returns the controller whose transition to
  /// wait for (or `nil` when it did nothing).
  private func perform(
    _ operation: @escaping (_ navigation: UINavigationController, _ top: UIViewController) -> UIViewController?)
  {
    queue.append { [weak self] done in
      guard let self else { return }
      whenIdle { [weak self] in
        guard let self else { return }
        let moving = operation(navigationController, topPresenter)
        Self.whenSettled(moving, done)
      }
    }
    runNext()
  }

  private func runNext() {
    guard !isRunning, !queue.isEmpty else { return }
    isRunning = true
    let operation = queue.removeFirst()
    operation { [weak self] in
      self?.isRunning = false
      self?.runNext()
    }
  }

  /// The controller that should present next: the topmost presented one.
  private var topPresenter: UIViewController {
    var top: UIViewController = navigationController
    while let presented = top.presentedViewController, !presented.isBeingDismissed {
      top = presented
    }
    return top
  }

  /// Runs `operation` once no transition is running on the stack or on the
  /// top presenter (one the person started, a swipe, included).
  private func whenIdle(_ operation: @escaping () -> Void) {
    guard let transition = topPresenter.transitionCoordinator ?? navigationController.transitionCoordinator else {
      operation()
      return
    }
    transition.animate(alongsideTransition: nil) { [weak self] _ in self?.whenIdle(operation) }
  }

  /// Calls `done` once the transition `controller` started has ended (at
  /// once when there is none: not animated, or nothing happened).
  private static func whenSettled(_ controller: UIViewController?, _ done: @escaping () -> Void) {
    guard let transition = controller?.transitionCoordinator else {
      done()
      return
    }
    transition.animate(alongsideTransition: nil) { _ in done() }
  }
}
