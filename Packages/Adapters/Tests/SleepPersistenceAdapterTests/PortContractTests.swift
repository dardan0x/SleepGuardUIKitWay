import Foundation
import SleepDomainTestSupport
import Testing
@testable import SleepPersistenceAdapter

/// The real stores meet the same contracts as the fakes
/// (`SleepDomainTestSupport.PortContracts`).
struct PersistenceContractTests {
  private func temporaryURL(_ name: String) -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(name)
  }

  @Test func swiftDataSessionStore() async {
    let violations = await PortContracts.sessionRepository { try SleepPersistenceAdapter.makeSessionRepository(storeURL: nil) }
    #expect(violations == [])
  }

  @Test func fileCheckpointStore() async {
    let url = temporaryURL("json")
    defer { try? FileManager.default.removeItem(at: url) }
    let violations = await PortContracts.checkpointStore { SleepPersistenceAdapter.makeCheckpointStore(url: url) }
    #expect(violations == [])
  }

  @Test func fileProfileStore() async {
    let url = temporaryURL("json")
    defer { try? FileManager.default.removeItem(at: url) }
    let violations = await PortContracts.profileStore { SleepPersistenceAdapter.makeProfileStore(url: url) }
    #expect(violations == [])
  }

  @Test func fileLifestyleLogStore() async {
    let url = temporaryURL("json")
    defer { try? FileManager.default.removeItem(at: url) }
    let violations = await PortContracts.lifestyleLogStore { SleepPersistenceAdapter.makeLifestyleLogStore(url: url) }
    #expect(violations == [])
  }

  @Test func userDefaultsPreferencesStore() async {
    let suite = "contract-\(UUID().uuidString)"
    defer { UserDefaults().removePersistentDomain(forName: suite) }
    let violations = await PortContracts.preferencesStore { SleepPersistenceAdapter.makePreferencesStore(suiteName: suite) }
    #expect(violations == [])
  }
}
