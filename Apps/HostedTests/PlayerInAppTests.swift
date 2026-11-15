import FactoryKit
import Foundation
import SleepCore
import Testing
import UIKit
@testable import AppShell
@testable import HistoryFeature
@testable import ScreenKit
@testable import SessionDetailFeature

/// The player in the running app, on the Debug sample nights and their clips:
/// it plays, advances to the next clip once the first has been heard, and
/// stops when the sheet closes.
@MainActor
struct PlayerInAppTests {
  @Test func playsAnEpisodeAndStopsOnClose() async throws {
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = try #require(scene.windows.first { $0.rootViewController is UITabBarController })
    let tabs = try #require(window.rootViewController as? UITabBarController)
    tabs.selectedIndex = try #require(Container.shared.brand().configuration.tabs.firstIndex(of: .history))
    let navigation = try #require(tabs.selectedViewController as? UINavigationController)
    navigation.popToRootViewController(animated: false)
    let list = try #require(navigation.viewControllers.first as? HostingScreen<HistoryScreen>)

    // A night with a snoring episode of more than one clip.
    let repository = Container.shared.sessionRepository()
    var summaries: [NightSummary] = []
    for await nights in await repository.observeSummaries() where !nights.isEmpty {
      summaries = nights
      break
    }
    var chosen: (NightSummary, [NightEvent])?
    for summary in summaries {
      let night = try await repository.session(id: summary.id)
      if let episode = night.displayableEpisodes.first(where: { $0.events.count > 1 }) {
        chosen = (summary, episode.events)
        break
      }
    }
    let (summary, episode) = try #require(chosen)
    list.rootView.content.routes.openNight(summary)
    let detail = try #require(await until { navigation.topViewController as? HostingScreen<SessionDetailScreen> })

    detail.rootView.content.routes.playEvents(episode, episode[0].id)
    let sheet = try #require(await until { navigation.presentedViewController as? UINavigationController })
    let player = try #require(sheet.viewControllers.first as? HostingScreen<PlayerScreen>)
    let model = player.rootView.content.model
    #expect(await until { model.isPlaying ? true : nil } == true)
    #expect(model.hasAudio)
    try await hold()

    // The first clip is at most 15 s; finishing it (once heard) moves on.
    #expect(await until(seconds: 20) { model.playlist.index == 1 ? true : nil } == true)

    sheet.viewControllers.first?.navigationItem.rightBarButtonItems?.first?.primaryAction?.performWithSender(nil, target: nil)
    #expect(await until { navigation.presentedViewController == nil ? true : nil } == true)
    #expect(!model.isPlaying)
    navigation.popToRootViewController(animated: false)
  }

  private func hold() async throws {
    if let seconds = ProcessInfo.processInfo.environment["SCREENSHOT_HOLD"].flatMap(Double.init) {
      try await Task.sleep(for: .seconds(seconds))
    }
  }

  private func until<T>(seconds: Double = 5, _ condition: () -> T?) async -> T? {
    for _ in 0..<Int(seconds * 10) {
      if let value = condition() { return value }
      try? await Task.sleep(for: .milliseconds(100))
    }
    return nil
  }
}
