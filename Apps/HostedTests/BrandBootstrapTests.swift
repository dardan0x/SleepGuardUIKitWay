import FactoryKit
import Foundation
import SleepDomain
import Testing
import UIKit
@testable import AppShell

/// Runs in every brand's app (one hosted test target per brand), against the
/// brand that app actually composed at launch.
@MainActor
struct BrandBootstrapTests {
  /// Every registration, resolved by name. A brand that can't provide one
  /// fails here instead of crashing a user.
  private static func resolvers(_ container: Container) -> [String: () -> Any] {
    [
      "brand": { container.brand() },
      "theme": { container.theme() },
      "storageLocation": { container.storageLocation() },
      "storeOpening": { container.storeOpening() },
      "sessionRepository": { container.sessionRepository() },
      "sessionFileStore": { container.sessionFileStore() },
      "sleepStageSource": { container.sleepStageSource() },
      "deleteSession": { container.deleteSession() },
      "refreshStaleSummaries": { container.refreshStaleSummaries() },
      "loadSessionDetail": { container.loadSessionDetail() },
      "enrichNightWithStages": { container.enrichNightWithStages() },
      "checkpointStore": { container.checkpointStore() },
      "saveRules": { container.saveRules() },
      "commitSession": { container.commitSession() },
      "preferencesStore": { container.preferencesStore() },
      "profileStore": { container.profileStore() },
      "lifestyleLogStore": { container.lifestyleLogStore() },
      "loadMorningBriefing": { container.loadMorningBriefing() },
      "shouldAskForProfile": { container.shouldAskForProfile() },
      "healthAccess": { container.healthAccess() as Any },
      "makeMelodyStore": { container.makeMelodyStore() as Any },
      "makeMelodyPlayer": { container.makeMelodyPlayer() },
      "makeMelodyRecorder": { container.makeMelodyRecorder() },
      "makeRawLogWriter": { container.makeRawLogWriter() },
      "enforceStorageLimits": { container.enforceStorageLimits() },
      "deleteAllData": { container.deleteAllData() },
      "discardRecording": { container.discardRecording() },
      "recoverInterruptedSession": { container.recoverInterruptedSession() },
      "makeAudioCapture": { container.makeAudioCapture() },
      "deviceServices": { container.deviceServices() },
      "clipWaveformSource": { container.clipWaveformSource() },
      "makeClipPlayer": { container.makeClipPlayer() },
    ]
  }

  @Test func everyRegistrationResolves() throws {
    let container = try HostedApp.container()
    for (_, resolve) in Self.resolvers(container) {
      _ = resolve()
    }
    let configuration = container.brand().configuration
    #expect(!configuration.tabs.isEmpty)
    #expect(container.theme() == configuration.theme)
    #expect(container.storeOpening().isAvailable)
    #expect(FileManager.default.fileExists(atPath: container.storageLocation().clipsDirectory.path))
  }

  /// The list above is every `Factory` the shell declares: a new one that
  /// isn't added here fails (read from the source, beside this file).
  @Test func theListCoversEveryRegistration() throws {
    let source = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent("Packages/AppShell/Sources/AppShell/Container+AppShell.swift")
    let text = try String(contentsOf: source, encoding: .utf8)
    let declared = Set(text.matches(of: /var (\w+): Factory</).map { String($0.1) })
    #expect(declared.count > 20)
    #expect(try Set(Self.resolvers(HostedApp.container()).keys) == declared)
  }

  /// Debug launches seed an empty store; waits on the store's own stream until
  /// all 14 are there (seeding saves them one by one, after writing their
  /// clips). The test time limit fails it if they never arrive.
  @Test func debugLaunchHasSampleNights() async throws {
    // Seeding starts once the tabs are up (after the onboarding).
    _ = try await HostedApp.tabBar()
    let repository = try HostedApp.container().sessionRepository()
    for await nights in await repository.observeSummaries() where nights.count >= 14 {
      return
    }
    Issue.record("The store's stream ended before 14 sample nights arrived")
  }

  @Test func theTabBarShowsTheBrandsTabsInOrder() async throws {
    let tabBar = try await HostedApp.tabBar()
    let expected = try HostedApp.container().brand().configuration.tabs

    #expect(tabBar.viewControllers?.compactMap(\.tabBarItem.title) == expected.map(\.title))
  }
}
