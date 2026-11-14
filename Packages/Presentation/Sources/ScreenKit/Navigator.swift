import UIKit

/// The navigation operations a coordinator performs. Coordinators depend on
/// this protocol, so tests drive them with a spy instead of UIKit.
public protocol Navigator: AnyObject {
  func setRoot(_ controller: UIViewController)
  func push(_ controller: UIViewController)
  func pop()
  func popToRoot()
  func present(_ controller: UIViewController, style: PresentationStyle)
  /// Dismisses the topmost presented controller.
  func dismiss()
}

public enum PresentationStyle: Equatable {
  case sheet(detents: [SheetDetent])
  case fullScreen
}

public enum SheetDetent: Equatable {
  case medium
  case large
}

/// `Navigator` over one `UINavigationController` (one per tab or flow).
///
/// UIKit misbehaves if you push or present while a transition is running
/// (warnings, a lost presentation, a stuck stack). Every operation therefore
/// waits for the running transition to finish, then runs. Nothing is dropped.
public final class NavigationControllerNavigator: Navigator {
  public let navigationController: UINavigationController
  private let animated: Bool

  /// `animated: false` is for tests.
  public init(navigationController: UINavigationController = UINavigationController(), animated: Bool = true) {
    self.navigationController = navigationController
    self.animated = animated
  }

  public func setRoot(_ controller: UIViewController) {
    whenIdle(navigationController) { [animated] navigation in
      navigation.setViewControllers([controller], animated: animated)
    }
  }

  public func push(_ controller: UIViewController) {
    whenIdle(navigationController) { [animated] navigation in
      navigation.pushViewController(controller, animated: animated)
    }
  }

  public func pop() {
    whenIdle(navigationController) { [animated] navigation in
      navigation.popViewController(animated: animated)
    }
  }

  public func popToRoot() {
    whenIdle(navigationController) { [animated] navigation in
      navigation.popToRootViewController(animated: animated)
    }
  }

  public func present(_ controller: UIViewController, style: PresentationStyle) {
    configure(controller, for: style)
    whenIdle(topPresenter) { [animated] presenter in
      presenter.present(controller, animated: animated)
    }
  }

  public func dismiss() {
    let top = topPresenter
    guard top !== navigationController else { return }
    whenIdle(top) { [animated] top in
      top.dismiss(animated: animated)
    }
  }

  /// Internal so tests can check it without presenting (package tests have no
  /// scene, so UIKit never finishes a presentation there).
  func configure(_ controller: UIViewController, for style: PresentationStyle) {
    switch style {
    case let .sheet(detents):
      controller.modalPresentationStyle = .pageSheet
      if let sheet = controller.sheetPresentationController {
        sheet.detents = detents.map { $0 == .medium ? .medium() : .large() }
        sheet.prefersGrabberVisible = detents.count > 1
      }
    case .fullScreen:
      controller.modalPresentationStyle = .fullScreen
    }
  }

  // MARK: - Private

  /// The controller that should present next: the topmost presented one.
  private var topPresenter: UIViewController {
    var top: UIViewController = navigationController
    while let presented = top.presentedViewController, !presented.isBeingDismissed {
      top = presented
    }
    return top
  }

  /// Runs `operation` now, or after the transition running on `controller` ends.
  private func whenIdle<Target: UIViewController>(_ controller: Target, _ operation: @escaping (Target) -> Void) {
    guard let transition = controller.transitionCoordinator else {
      operation(controller)
      return
    }
    transition.animate(alongsideTransition: nil) { _ in operation(controller) }
  }
}
