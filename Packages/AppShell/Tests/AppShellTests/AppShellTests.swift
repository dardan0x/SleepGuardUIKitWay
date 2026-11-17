import AppShellTestSupport
import FactoryKit
import SleepGuardDesignKit
import SwiftUI
import Testing
import UIKit
@testable import AppShell
@testable import ScreenKit

/// Each test builds its own `Container`, so tests don't share the global one.
struct MainTabCoordinatorTests {
  @Test func tabsFollowTheBrandsListAndOrder() {
    let coordinator = MainTabCoordinator(container: container(TestBrand(tabs: [.history, .statistics, .settings])))
    let items = coordinator.tabBarController.viewControllers?.compactMap(\.tabBarItem)
    #expect(items?.map(\.title) == [Strings.tabSessions, Strings.tabStatistics, Strings.tabSettings])
    #expect(coordinator.flows.map(\.tab) == [.history, .statistics, .settings])
    #expect(coordinator.flows.first is HistoryFlow)
    #expect(coordinator.flows[1] is StatisticsFlow)
    #expect(coordinator.flows[2] is SettingsFlow)
  }

  @Test func everyTabStartsOnItsOwnHostedScreenWithItsTitle() throws {
    let coordinator = MainTabCoordinator(container: container(TestBrand(tabs: [.statistics, .learn])))
    let navigations = try #require(coordinator.tabBarController.viewControllers as? [UINavigationController])
    #expect(navigations.map(\.viewControllers.count) == [1, 1])
    #expect(navigations.map(\.viewControllers.first?.navigationItem.title) == [Strings.tabStatistics, Strings.tabLearn])
  }

  @Test func barsUseTheBrandTheme() throws {
    var theme = Theme.sleepGuard
    theme.palette.accent = Color(hex: "#9B7BFF")
    theme.palette.bgSecondary = Color(hex: "#221640")
    let coordinator = MainTabCoordinator(container: container(TestBrand(theme: theme, tabs: [.statistics])))

    let tabBar = coordinator.tabBarController.tabBar
    #expect(tabBar.standardAppearance.backgroundColor == UIColor(theme.palette.bgSecondary))
    #expect(tabBar.standardAppearance.stackedLayoutAppearance.selected.iconColor == UIColor(theme.palette.accent))
    let navigation = try #require(coordinator.tabBarController.viewControllers?.first as? UINavigationController)
    #expect(navigation.navigationBar.standardAppearance.backgroundColor == UIColor(theme.palette.bgPrimary))
    #expect(navigation.navigationBar.tintColor == UIColor(theme.palette.accent))
  }

  @Test func navigationTitlesUseTheThemesTypeDesign() throws {
    var theme = Theme.sleepGuard
    theme.typography = Typography(design: .rounded)
    let coordinator = MainTabCoordinator(container: container(TestBrand(theme: theme, tabs: [.statistics])))
    let navigation = try #require(coordinator.tabBarController.viewControllers?.first as? UINavigationController)

    let largeTitle = try #require(navigation.navigationBar.standardAppearance.largeTitleTextAttributes[.font] as? UIFont)
    let title = try #require(navigation.navigationBar.standardAppearance.titleTextAttributes[.font] as? UIFont)
    // System fonts carry their design in the name (e.g. ".SFUIRounded-Bold").
    #expect(largeTitle.fontName.localizedCaseInsensitiveContains("rounded"), "\(largeTitle.fontName)")
    #expect(title.fontName.localizedCaseInsensitiveContains("rounded"), "\(title.fontName)")
    #expect(Appearance.font(.sleepGuard, style: .headline, weight: .semibold).fontName.localizedCaseInsensitiveContains("rounded") == false)
  }

  private func container(_ brand: TestBrand) -> Container {
    Container.test(brand: brand)
  }
}

struct PlaceholderFlowTests {
  @Test func startSetsTheRootScreen() throws {
    let spy = NavigatorSpy()
    let flow = PlaceholderFlow(tab: .history, navigator: spy, composer: PlaceholderScreenComposer(theme: .sleepGuard))
    flow.start()
    guard case let .setRoot(root) = try #require(spy.calls.first) else {
      Issue.record("expected setRoot, got \(spy.calls)")
      return
    }
    #expect(root.navigationItem.title == Strings.tabSessions)
  }

  /// A route closure from the screen becomes a navigator call: the screen asks,
  /// the flow decides how.
  @Test func continueRoutePresentsASheetAndCloseDismissesIt() throws {
    let spy = NavigatorSpy()
    let flow = PlaceholderFlow(tab: .history, navigator: spy, composer: PlaceholderScreenComposer(theme: .sleepGuard))
    flow.start()
    let root = try #require(rootScreen(spy))

    root.rootView.content.routes.showDetails()
    guard case let .present(sheet, style) = spy.calls.last else {
      Issue.record("expected present, got \(spy.calls)")
      return
    }
    #expect(style == .sheet(detents: [.medium, .large]))

    let presented = try #require(sheet as? HostingScreen<PlaceholderScreen>)
    presented.rootView.content.routes.close?()
    #expect(spy.calls.last == .dismiss)
  }

  @Test func theFlowIsNotRetainedByItsScreens() throws {
    let spy = NavigatorSpy()
    var flow: PlaceholderFlow? = PlaceholderFlow(
      tab: .history, navigator: spy, composer: PlaceholderScreenComposer(theme: .sleepGuard))
    flow?.start()
    weak var weakFlow = flow
    flow = nil
    #expect(weakFlow == nil)
  }

  private func rootScreen(_ spy: NavigatorSpy) -> HostingScreen<PlaceholderScreen>? {
    guard case let .setRoot(root) = spy.calls.first else { return nil }
    return root as? HostingScreen<PlaceholderScreen>
  }
}
