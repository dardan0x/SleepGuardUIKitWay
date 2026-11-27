import FactoryKit
import Foundation
import SleepCore
import SleepDomain
import Testing
import UIKit
@testable import AppShell
@testable import HistoryFeature
@testable import ScreenKit
@testable import SessionDetailFeature

/// The Sessions tab inside the running app: the real flow, navigation stack
/// and store (Debug sample nights). Set `TEST_RUNNER_SCREENSHOT_DIR` to save
/// screenshots of the list and the detail.
@MainActor
struct SessionsTabInAppTests {
  @Test func openingANightPushesItsDetail() async throws {
    let tabs = try await HostedApp.tabBar()
    let window = try #require(tabs.view.window)
    let index = try #require(try HostedApp.container().brand().configuration.tabs.firstIndex(of: .history))
    tabs.selectedIndex = index
    let navigation = try #require(tabs.selectedViewController as? UINavigationController)
    navigation.popToRootViewController(animated: false)
    let list = try #require(navigation.viewControllers.first as? HistoryViewController)
    let nights = await firstNonEmptyList()
    let screenshots = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"]
    if let screenshots { try await capture(window, to: screenshots, name: "sessions-list") }

    try list.viewModel.routes.openNight(#require(nights.first))

    let detail = try #require(navigation.topViewController as? SessionDetailViewController)
    #expect(detail.navigationItem.rightBarButtonItems?.count == 2)
    if let screenshots { try await capture(window, to: screenshots, name: "sessions-detail") }

    // "Show all": the events sheet at medium and large; close returns to the detail.
    let loaded = try await HostedApp.container().loadSessionDetail()(#require(nights.first).id)
    let rows = EventListRow.rows(for: loaded.session)
    detail.viewModel.routes.showAllEvents(rows, loaded.session.events)
    let sheet = try #require(await until { navigation.presentedViewController as? UINavigationController })
    #expect(sheet.sheetPresentationController?.detents.map(\.identifier) == [.medium, .large])
    let events = try #require(sheet.viewControllers.first as? EventsSheetViewController)
    if let screenshots { try await capture(window, to: screenshots, name: "sessions-events") }

    events.navigationItem.rightBarButtonItems?.first?.primaryAction?.performWithSender(nil, target: nil)
    #expect(await until { navigation.presentedViewController == nil ? true : nil } == true)
    #expect(navigation.topViewController === detail)
    navigation.popToRootViewController(animated: false)
  }

  /// A popped detail is released with its view model: nothing (a route
  /// closure, a render task, the flow) keeps the screen alive.
  @Test func aPoppedDetailIsReleased() async throws {
    let tabs = try await HostedApp.tabBar()
    let index = try #require(try HostedApp.container().brand().configuration.tabs.firstIndex(of: .history))
    tabs.selectedIndex = index
    let navigation = try #require(tabs.selectedViewController as? UINavigationController)
    navigation.popToRootViewController(animated: false)
    let list = try #require(navigation.viewControllers.first as? HistoryViewController)
    let nights = await firstNonEmptyList()
    weak var weakDetail: SessionDetailViewController?
    weak var weakViewModel: SessionDetailViewModel?
    do {
      try list.viewModel.routes.openNight(#require(nights.first))
      let detail = try #require(await until { navigation.topViewController as? SessionDetailViewController })
      _ = await until { detail.viewModel.needsLoading ? nil : true } // let its load finish
      weakDetail = detail
      weakViewModel = detail.viewModel
    }

    navigation.popToRootViewController(animated: false)

    #expect(await until { weakDetail == nil ? true : nil } == true)
    #expect(weakViewModel == nil)
  }

  /// Polls (UIKit transitions have no completion to await here) for up to 5 s.
  private func until<T>(_ condition: () -> T?) async -> T? {
    for _ in 0..<50 {
      if let value = condition() { return value }
      try? await Task.sleep(for: .milliseconds(100))
    }
    return nil
  }

  private func firstNonEmptyList() async -> [NightSummary] {
    guard let repository = try? HostedApp.container().sessionRepository() else { return [] }
    for await nights in await repository.observeSummaries() where !nights.isEmpty {
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
