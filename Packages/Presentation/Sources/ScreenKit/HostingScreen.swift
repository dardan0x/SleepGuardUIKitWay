import SleepGuardDesignKit
import SwiftUI
import UIKit

/// The one `UIHostingController` subclass. Every SwiftUI screen is shown in
/// one: it puts the brand's theme into the SwiftUI environment, paints the
/// background, and applies the screen's `ScreenChrome` to the navigation bar.
///
/// Per-screen differences are data (`ScreenChrome`), so no screen needs its
/// own hosting controller.
public final class HostingScreen<Content: View>: UIHostingController<ThemedScreen<Content>> {
  public let chrome: ScreenChrome
  private let theme: Theme

  public init(rootView: Content, theme: Theme, chrome: ScreenChrome = ScreenChrome()) {
    self.chrome = chrome
    self.theme = theme
    super.init(rootView: ThemedScreen(theme: theme, content: rootView))
    applyChrome()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("HostingScreen is created in code by a composer")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(theme.palette.bgPrimary)
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(chrome.hidesNavigationBar, animated: animated)
  }

  private func applyChrome() {
    navigationItem.title = chrome.title
    navigationItem.largeTitleDisplayMode = chrome.largeTitle ? .always : .never
    navigationItem.rightBarButtonItems = chrome.trailingItems.reversed().map { item in
      let button = UIBarButtonItem(
        image: UIImage(systemName: item.systemImage),
        primaryAction: UIAction { _ in item.action() })
      button.accessibilityLabel = item.accessibilityLabel
      return button
    }
  }
}

/// A screen's content with the brand theme in its environment.
public struct ThemedScreen<Content: View>: View {
  let theme: Theme
  let content: Content

  public var body: some View {
    content.environment(\.theme, theme)
  }
}
