import SleepGuardDesignKit
import SwiftUI
import Testing
import UIKit
@testable import ScreenKit

struct HostingScreenTests {
  @Test func chromeIsAppliedToTheNavigationItem() {
    let screen = HostingScreen(
      rootView: Color.clear,
      theme: .sleepGuard,
      chrome: ScreenChrome(
        title: "History",
        largeTitle: true,
        trailingItems: [
          BarItem(systemImage: "square.and.arrow.up", accessibilityLabel: "Share") {},
          BarItem(systemImage: "trash", accessibilityLabel: "Delete") {},
        ]))

    #expect(screen.navigationItem.title == "History")
    #expect(screen.navigationItem.largeTitleDisplayMode == .always)
    // UIKit lays out right bar items right to left; listed order reads left to right.
    #expect(screen.navigationItem.rightBarButtonItems?.map(\.accessibilityLabel) == ["Delete", "Share"])
  }

  @Test func defaultChromeHasNoTitleAndNoLargeTitle() {
    let screen = HostingScreen(rootView: Color.clear, theme: .sleepGuard)
    #expect(screen.navigationItem.title == nil)
    #expect(screen.navigationItem.largeTitleDisplayMode == .never)
    #expect(screen.navigationItem.rightBarButtonItems?.isEmpty ?? true)
  }

  @Test func backgroundIsTheThemeBackground() {
    var theme = Theme.sleepGuard
    theme.palette.bgPrimary = Color(hex: "#120A24")
    let screen = HostingScreen(rootView: Color.clear, theme: theme)
    screen.loadViewIfNeeded()
    #expect(screen.view.backgroundColor == UIColor(theme.palette.bgPrimary))
  }

  @Test func theThemeReachesTheSwiftUIContent() {
    var theme = Theme.sleepGuard
    theme.palette.accent = Color(hex: "#9B7BFF")
    let seen = ThemeBox()
    let screen = HostingScreen(rootView: ThemeProbe(seen: seen), theme: theme)

    _ = ImageRenderer(content: screen.rootView).uiImage

    #expect(seen.theme == theme)
  }

  @Test func hidesTheNavigationBarWhenAsked() {
    let screen = HostingScreen(rootView: Color.clear, theme: .sleepGuard, chrome: ScreenChrome(hidesNavigationBar: true))
    let navigation = UINavigationController(rootViewController: screen)
    screen.beginAppearanceTransition(true, animated: false)
    screen.endAppearanceTransition()
    #expect(navigation.isNavigationBarHidden)
  }
}

/// Records the theme its body sees.
private final class ThemeBox {
  var theme: Theme?
}

private struct ThemeProbe: View {
  let seen: ThemeBox
  @Environment(\.theme) private var theme

  var body: some View {
    seen.theme = theme
    return Color.clear.frame(width: 10, height: 10)
  }
}
