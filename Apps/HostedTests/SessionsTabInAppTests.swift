import FactoryKit
import Foundation
import SessionDetailFeature
import SleepCore
import SleepDomain
import Testing
import UIKit
@testable import AppShell
@testable import HistoryFeature
@testable import ScreenKit

/// The Sessions tab inside the running app: the real flow, navigation stack
/// and store (Debug sample nights). Set `TEST_RUNNER_SCREENSHOT_DIR` to save
/// screenshots of the list and the detail.
@MainActor
struct SessionsTabInAppTests {
  @Test func openingANightPushesItsDetail() async throws {
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = try #require(scene.windows.first { $0.rootViewController is UITabBarController })
    let tabs = try #require(window.rootViewController as? UITabBarController)
    let index = try #require(Container.shared.brand().configuration.tabs.firstIndex(of: .history))
    tabs.selectedIndex = index
    let navigation = try #require(tabs.selectedViewController as? UINavigationController)
    navigation.popToRootViewController(animated: false)
    let list = try #require(navigation.viewControllers.first as? HostingScreen<HistoryScreen>)
    let nights = await firstNonEmptyList()
    let screenshots = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"]
    if let screenshots { try await capture(window, to: screenshots, name: "sessions-list") }

    try list.rootView.content.routes.openNight(#require(nights.first))

    let detail = try #require(navigation.topViewController as? HostingScreen<SessionDetailScreen>)
    #expect(detail.navigationItem.rightBarButtonItems?.count == 1)
    if let screenshots { try await capture(window, to: screenshots, name: "sessions-detail") }
    navigation.popToRootViewController(animated: false)
  }

  private func firstNonEmptyList() async -> [NightSummary] {
    for await nights in await Container.shared.sessionRepository().observeSummaries() where !nights.isEmpty {
      return nights
    }
    return []
  }

  /// Screenshots only: gives transitions and loading time to settle, then draws.
  private func capture(_ window: UIWindow, to directory: String, name: String) async throws {
    try await Task.sleep(for: .seconds(1.5))
    // Optional hold so an outside `simctl io screenshot` can catch the screen too.
    if let hold = ProcessInfo.processInfo.environment["SCREENSHOT_HOLD"].flatMap(Double.init) {
      try await Task.sleep(for: .seconds(hold))
    }
    let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
      window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }
    let brand = Bundle.main.bundleIdentifier?.components(separatedBy: ".").last ?? "app"
    try image.pngData()?.write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(brand)-\(name).png"))
  }
}
