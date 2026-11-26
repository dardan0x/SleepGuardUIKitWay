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
    let coordinator = AppComposition(container: container(TestBrand(tabs: [.history, .statistics, .settings]))).mainTabs()
    let items = coordinator.tabBarController.viewControllers?.compactMap(\.tabBarItem)
    #expect(items?.map(\.title) == [Strings.tabSessions, Strings.tabStatistics, Strings.tabSettings])
    #expect(coordinator.flows.map(\.tab) == [.history, .statistics, .settings])
    #expect(coordinator.flows.first is HistoryFlow)
    #expect(coordinator.flows[1] is StatisticsFlow)
    #expect(coordinator.flows[2] is SettingsFlow)
    let withLearn = AppComposition(container: container(TestBrand(tabs: [.statistics, .learn]))).mainTabs()
    #expect(withLearn.flows.last is LearnFlow)
  }

  @Test func everyTabStartsOnItsOwnHostedScreenWithItsTitle() throws {
    let coordinator = AppComposition(container: container(TestBrand(tabs: [.statistics, .learn]))).mainTabs()
    let navigations = try #require(coordinator.tabBarController.viewControllers as? [UINavigationController])
    #expect(navigations.map(\.viewControllers.count) == [1, 1])
    #expect(navigations.map(\.viewControllers.first?.navigationItem.title) == [Strings.tabStatistics, Strings.tabLearn])
  }

  @Test func barsUseTheBrandTheme() throws {
    var theme = Theme.sleepGuard
    theme.palette.accent = Color(hex: "#9B7BFF")
    theme.palette.bgSecondary = Color(hex: "#221640")
    let coordinator = AppComposition(container: container(TestBrand(theme: theme, tabs: [.statistics]))).mainTabs()

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
    let coordinator = AppComposition(container: container(TestBrand(theme: theme, tabs: [.statistics]))).mainTabs()
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
