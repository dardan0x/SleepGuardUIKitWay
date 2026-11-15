import FactoryKit
import SleepDomain
import Testing
import UIKit
@testable import AppShell

/// Runs in every brand's app (one hosted test target per brand), against the
/// brand that app actually bootstrapped at launch.
@MainActor
struct BrandBootstrapTests {
  /// Resolves every registration in the shell's container. Add each new
  /// factory here: a brand that can't provide one should fail this test, not
  /// crash a user.
  @Test func everyRegistrationResolves() {
    let container = Container.shared
    let configuration = container.brand().configuration
    #expect(!configuration.tabs.isEmpty)
    #expect(container.theme() == configuration.theme)
    _ = container.sessionRepository()
    _ = container.sessionFileStore()
    #expect(FileManager.default.fileExists(atPath: container.storageLocation().clipsDirectory.path))
  }

  /// Debug launches seed an empty store; waits on the store's own stream until
  /// all 14 are there (seeding saves them one by one, after writing their
  /// clips). The test time limit fails it if they never arrive.
  @Test func debugLaunchHasSampleNights() async {
    let repository = Container.shared.sessionRepository()
    for await nights in await repository.observeSummaries() where nights.count >= 14 {
      return
    }
    Issue.record("The store's stream ended before 14 sample nights arrived")
  }

  @Test func theTabBarShowsTheBrandsTabsInOrder() throws {
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let tabBar = try #require(scene.windows.compactMap { $0.rootViewController as? UITabBarController }.first)
    let expected = Container.shared.brand().configuration.tabs

    #expect(tabBar.viewControllers?.compactMap(\.tabBarItem.title) == expected.map(\.title))
  }
}
