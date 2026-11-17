import Foundation
import SleepCore
import Testing
@testable import SleepAudio

/// Recordings are kept with SleepCore's ids and names and survive a relaunch;
/// built-ins come from the shared bundle.
@MainActor
struct FileMelodyStoreTests {
  let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

  func makeTake() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
    try Data([1, 2, 3]).write(to: url)
    return url
  }

  @Test func aBuiltInHasItsSharedFile() throws {
    let store = FileMelodyStore(directory: directory)
    let url = try #require(store.url(for: Melody.resolve(id: 6, custom: [])))
    #expect(FileManager.default.fileExists(atPath: url.path))
  }

  @Test func aSavedTakeIsARecordingThatSurvivesARelaunch() throws {
    let store = FileMelodyStore(directory: directory)
    let first = try #require(store.save(take: try makeTake(), name: "My Sound 1"))
    let second = try #require(store.save(take: try makeTake(), name: "My Sound 2"))
    #expect(first.id == 100)
    #expect(second.id == 101)
    #expect(first.filename == "custom_100.m4a")
    #expect(store.url(for: first) != nil)

    let relaunched = FileMelodyStore(directory: directory)
    #expect(relaunched.recordings() == [first, second])
  }

  @Test func deletingRemovesTheFileAndNeverReusesTheId() throws {
    let store = FileMelodyStore(directory: directory)
    let first = try #require(store.save(take: try makeTake(), name: "A"))
    store.delete(first)
    #expect(store.recordings().isEmpty)
    #expect(store.url(for: first) == nil)
    let next = try #require(store.save(take: try makeTake(), name: "B"))
    #expect(next.id == 101)
  }
}
