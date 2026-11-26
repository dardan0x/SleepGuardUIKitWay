import ScreenKit
import UIKit

/// Records what a coordinator asked the navigator to do, so flows are tested
/// without UIKit transitions.
public final class NavigatorSpy: Navigator {
  public enum Call: Equatable {
    case setRoot(UIViewController)
    case push(UIViewController)
    case pop
    case popToRoot
    case present(UIViewController, PresentationStyle)
    case dismiss(UIViewController)
  }

  public private(set) var calls: [Call] = []

  public init() {}

  public func setRoot(_ controller: UIViewController) {
    calls.append(.setRoot(controller))
  }

  public func push(_ controller: UIViewController) {
    calls.append(.push(controller))
  }

  public func pop() {
    calls.append(.pop)
  }

  public func popToRoot() {
    calls.append(.popToRoot)
  }

  public func present(_ controller: UIViewController, style: PresentationStyle) {
    calls.append(.present(controller, style))
  }

  public func dismiss(_ controller: UIViewController) {
    calls.append(.dismiss(controller))
  }
}
