import SleepGuardDesignKit
import SwiftUI
import Testing
import UIKit
@testable import ScreenKit

/// The base of every screen: chrome and background, one state child at a
/// time, the theme in what it hosts, and UIKit fonts that follow the theme.
struct ScreenControllerTests {
  @Test func chromeIsAppliedToTheNavigationItem() {
    let screen = ScreenController(
      theme: .sleepGuard,
      chrome: ScreenChrome(title: "Sessions", trailingItems: [BarItem(systemImage: "trash", accessibilityLabel: "Delete") {}]))
    #expect(screen.navigationItem.title == "Sessions")
    #expect(screen.navigationItem.largeTitleDisplayMode == .never)
    #expect(screen.navigationItem.rightBarButtonItems?.map(\.accessibilityLabel) == ["Delete"])
  }

  @Test func backgroundIsTheThemeBackground() {
    var theme = Theme.sleepGuard
    theme.palette.bgPrimary = Color(hex: "#120A24")
    let screen = ScreenController(theme: theme)
    screen.loadViewIfNeeded()
    #expect(screen.view.backgroundColor == UIColor(theme.palette.bgPrimary))
  }

  @Test func hidesTheNavigationBarWhenAsked() {
    let screen = ScreenController(theme: .sleepGuard, chrome: ScreenChrome(hidesNavigationBar: true))
    let navigation = UINavigationController(rootViewController: screen)
    screen.beginAppearanceTransition(true, animated: false)
    screen.endAppearanceTransition()
    #expect(navigation.isNavigationBarHidden)
  }

  @Test func showingAStateReplacesThePreviousOne() {
    let screen = ScreenController(theme: .sleepGuard)
    screen.loadViewIfNeeded()
    let loading = UIViewController()
    let loaded = UIViewController()

    screen.show(loading)
    screen.show(loaded)

    #expect(screen.children == [loaded])
    #expect(loading.view.superview == nil)
    #expect(loaded.view.superview === screen.view)
    #expect(screen.stateChild === loaded)
  }

  @Test func aStateSitsBelowTheHeader() {
    let screen = ScreenController(theme: .sleepGuard)
    screen.loadViewIfNeeded()
    screen.setHeader(Text("Title"))
    let loaded = UIViewController()

    screen.show(loaded)

    #expect(screen.children.count == 2)
    #expect(screen.stateChild === loaded)
    let header = screen.children.first { $0 !== loaded }?.view
    #expect(screen.view.constraints.contains { constraint in
      constraint.firstItem === loaded.view && constraint.firstAttribute == .top
        && constraint.secondItem === header && constraint.secondAttribute == .bottom
    })
  }

  @Test func renderingTheSameKindOfContentRedrawsInPlace() {
    let screen = ScreenController(theme: .sleepGuard)
    screen.loadViewIfNeeded()
    screen.render(Text("a"))
    let first = screen.stateChild
    screen.render(Text("b"))
    #expect(screen.stateChild === first)
    screen.render(Color.clear)
    #expect(screen.stateChild !== first)
  }

  @Test func hostedContentGetsTheTheme() {
    var theme = Theme.sleepGuard
    theme.palette.accent = Color(hex: "#9B7BFF")
    let seen = ThemeBox()
    let hosted = ScreenController(theme: theme).host(ThemeProbe(seen: seen))
    _ = ImageRenderer(content: hosted.rootView).uiImage
    #expect(seen.theme == theme)
    #expect(hosted.view.backgroundColor == .clear)
  }

  @Test func uiKitFontsFollowTheThemesDesign() {
    let rounded = Typography(design: .rounded).uiFont(size: 15, weight: .semibold)
    #expect(rounded.pointSize == 15)
    #expect(rounded.fontName != UIFont.systemFont(ofSize: 15, weight: .semibold).fontName)
    #expect(Typography.uiWeight(.semibold) == .semibold)
    #expect(Typography.uiDesign(.serif) == .serif)
  }
}

/// Rows in order, redrawn when set; only rows with a tap are tappable.
@MainActor
struct ContentListControllerTests {
  @Test func showsTheRowsInOrder() {
    var tapped = 0
    let list = ContentListController(rows: [
      .init(id: "a", configuration: UIListContentConfiguration.cell()),
      .init(id: "b", configuration: UIListContentConfiguration.cell()) { tapped += 1 },
    ])
    list.loadViewIfNeeded()
    #expect(list.collectionView.numberOfItems(inSection: 0) == 2)
    let b = IndexPath(item: 1, section: 0)
    #expect(!list.collectionView(list.collectionView, shouldHighlightItemAt: IndexPath(item: 0, section: 0)))
    #expect(list.collectionView(list.collectionView, shouldHighlightItemAt: b))
    list.collectionView(list.collectionView, didSelectItemAt: b)
    #expect(tapped == 1)

    list.rows = [.init(id: "c", configuration: UIListContentConfiguration.cell())]
    #expect(list.collectionView.numberOfItems(inSection: 0) == 1)
  }
}

@Observable
@MainActor
final class Counter {
  var value = 0
}

@MainActor
struct RenderTrackingTests {
  @Test func rendersAgainWhenAnObservedValueChanges() async {
    let counter = Counter()
    let screen = ScreenController(theme: .sleepGuard)
    let seen = ValueBox()
    screen.renderTracking { seen.values.append(counter.value) }
    counter.value = 1
    await Task.yield()
    await Task.yield()
    #expect(seen.values == [0, 1])
  }
}

@MainActor
final class ValueBox {
  var values: [Int] = []
}

/// Records the theme its body sees.
final class ThemeBox {
  var theme: Theme?
}

struct ThemeProbe: View {
  let seen: ThemeBox
  @Environment(\.theme) private var theme

  var body: some View {
    seen.theme = theme
    return Color.clear.frame(width: 10, height: 10)
  }
}
