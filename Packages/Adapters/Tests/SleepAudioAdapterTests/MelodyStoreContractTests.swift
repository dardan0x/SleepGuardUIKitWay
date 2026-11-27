import Foundation
import SleepDomainTestSupport
import Testing
@testable import SleepAudioAdapter

/// The file melody store meets the same contract as the fake
/// (`SleepDomainTestSupport.PortContracts`).
@MainActor
struct MelodyStoreContractTests {
  @Test func fileMelodyStore() {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let violations = PortContracts.melodyStore({ SleepAudioAdapter.makeMelodyStore(directory: directory) }, take: {
      let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
      try Data([1, 2, 3]).write(to: url)
      return url
    })
    #expect(violations == [])
  }
}
