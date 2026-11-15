import FactoryKit
import Foundation
import Testing
import UIKit
@testable import AppShell
@testable import ScreenKit
@testable import StatisticsFeature

/// The Statistics tab inside the running app: the real flow and store (Debug
/// sample nights). Set `TEST_RUNNER_SCREENSHOT_HOLD` (seconds) to pause on
/// each screen for an outside `simctl io screenshot`.
@MainActor
struct StatisticsTabInAppTests {
  @Test func dashboardOpensTheCalendarFromTheBar() async throws {
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = try #require(scene.windows.first { $0.rootViewController is UITabBarController })
    let tabs = try #require(window.rootViewController as? UITabBarController)
    let index = try #require(Container.shared.brand().configuration.tabs.firstIndex(of: .statistics))
    tabs.selectedIndex = index
    let navigation = try #require(tabs.selectedViewController as? UINavigationController)
    navigation.popToRootViewController(animated: false)
    let dashboard = try #require(navigation.viewControllers.first as? HostingScreen<StatisticsScreen>)
    try await hold()

    dashboard.navigationItem.rightBarButtonItems?.first?.primaryAction?.performWithSender(nil, target: nil)
    let calendar = await until { navigation.topViewController as? HostingScreen<CalendarScreen> }
    #expect(calendar != nil)
    try await hold()
    navigation.popToRootViewController(animated: false)
  }

  private func hold() async throws {
    if let seconds = ProcessInfo.processInfo.environment["SCREENSHOT_HOLD"].flatMap(Double.init) {
      try await Task.sleep(for: .seconds(seconds))
    }
  }

  /// Polls (UIKit transitions have no completion to await here) for up to 5 s.
  private func until<T>(_ condition: () -> T?) async -> T? {
    for _ in 0..<50 {
      if let value = condition() { return value }
      try? await Task.sleep(for: .milliseconds(100))
    }
    return nil
  }
}
