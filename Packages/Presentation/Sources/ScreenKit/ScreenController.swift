import Observation
import SleepGuardDesignKit
import SwiftUI
import UIKit

/// The base of every screen (ADR 0007). UIKit owns the screen: its
/// structure (a collection view, a page view controller, or one hosted
/// piece), its state, its alerts. The shared SwiftUI content draws inside
/// it. This class gives each screen the brand background, its
/// `ScreenChrome`, the theme for anything it hosts, and its current state as
/// one child controller at a time.
///
/// A screen subclasses it; it never navigates (its `Routes` do that).
open class ScreenController: UIViewController {
  public let theme: Theme
  public let chrome: ScreenChrome
  /// The child showing the current state (loading, empty, loaded, error).
  public private(set) var stateChild: UIViewController?

  public init(theme: Theme, chrome: ScreenChrome = ScreenChrome()) {
    self.theme = theme
    self.chrome = chrome
    super.init(nibName: nil, bundle: nil)
    chrome.apply(to: navigationItem)
  }

  @available(*, unavailable)
  public required init?(coder _: NSCoder) {
    fatalError("A ScreenController is created in code by a composer")
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(theme.palette.bgPrimary)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(chrome.hidesNavigationBar, animated: animated)
  }

  /// Replaces the state child with `child`, filling the view.
  public func show(_ child: UIViewController) {
    guard child !== stateChild else { return }
    if let old = stateChild {
      old.willMove(toParent: nil)
      old.view.removeFromSuperview()
      old.removeFromParent()
    }
    addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(child.view)
    NSLayoutConstraint.activate([
      child.view.topAnchor.constraint(equalTo: view.topAnchor),
      child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    child.didMove(toParent: self)
    stateChild = child
    // The bar's large title and scroll edge follow the state's scroll view,
    // which UIKit can't find on its own inside a child.
    setContentScrollView(Self.firstScrollView(in: child.view), for: .top)
  }

  private static func firstScrollView(in view: UIView) -> UIScrollView? {
    if let scroll = view as? UIScrollView { return scroll }
    return view.subviews.lazy.compactMap { firstScrollView(in: $0) }.first
  }

  /// Shows shared `content` as the state child: hosted the first time, then
  /// redrawn in place while the state child hosts the same kind of content.
  /// A screen calls it again whenever its state changes.
  public func render<Content: View>(_ content: Content) {
    if let hosting = stateChild as? UIHostingController<ThemedScreen<Content>> {
      hosting.rootView = ThemedScreen(theme: theme, content: content)
    } else {
      show(host(content))
    }
  }

  /// A shared view as a cell's content, with this screen's theme and no
  /// margins (the shared view brings its own padding).
  public func hosted(@ViewBuilder _ content: () -> some View) -> any UIContentConfiguration {
    UIHostingConfiguration { content().environment(\.theme, theme) }.margins(.all, 0)
  }

  /// Presents the alert for a view model's due `alert`, unless one is
  /// already showing. Its actions answer the view model, which clears it;
  /// call this from `render` so a newly due alert comes up.
  public func presentAlert<Due>(_ due: Due?, make: (Due) -> UIAlertController) {
    guard let due, !(presentedViewController is UIAlertController) else { return }
    present(make(due), animated: viewIfLoaded?.window != nil)
  }

  /// Runs `render` now, and again after any `@Observable` value it read
  /// changes (a state owner such as the player's model). Stops when the
  /// screen is gone.
  public func renderTracking(_ render: @escaping @MainActor @Sendable () -> Void) {
    withObservationTracking(render) { [weak self] in
      Task { @MainActor [weak self] in self?.renderTracking(render) }
    }
  }

  /// SwiftUI content in a controller with this screen's theme and a clear
  /// background, for a state child or a page.
  public func host<Content: View>(_ content: Content) -> UIHostingController<ThemedScreen<Content>> {
    let controller = UIHostingController(rootView: ThemedScreen(theme: theme, content: content))
    controller.view.backgroundColor = .clear
    return controller
  }
}

/// A screen's content with the brand theme in its environment.
public struct ThemedScreen<Content: View>: View {
  let theme: Theme
  let content: Content

  public init(theme: Theme, content: Content) {
    self.theme = theme
    self.content = content
  }

  public var body: some View {
    content.environment(\.theme, theme)
  }
}
