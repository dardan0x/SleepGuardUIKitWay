import Foundation
import SleepCore
import Testing
@testable import SleepPersistence

/// The checkpoint file: a night goes in and comes back equal; no file, an
/// unreadable file and a cleared one all read as nothing.
struct FileCheckpointStoreTests {
  private let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
  private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  private var night: Night {
    Night(
      start: start, end: start.addingTimeInterval(3600), averageDB: -48.5, peakDB: -12,
      events: [
        NightEvent(
          start: start.addingTimeInterval(600), duration: 42, intensity: .loud, averageDB: -30, peakDB: -12,
          averageConfidence: 0.7, bursts: [SnoreBurst(startOffset: 0, endOffset: 3.5)], clipFileName: "a.m4a"),
        NightEvent(start: start.addingTimeInterval(1200), duration: 4, category: .sleepTalking, intensity: .quiet),
      ],
      recordingGaps: [RecordingGap(startOffset: 900, duration: 30, snoringResumed: true)],
      endReason: .lowBattery)
  }

  @Test func aNightComesBackEqual() async {
    defer { try? FileManager.default.removeItem(at: url) }
    let store = FileCheckpointStore(url: url)
    let night = night
    await store.save(night)
    #expect(await store.load() == night)
    // A new store on the same file: what the next launch sees.
    #expect(await FileCheckpointStore(url: url).load() == night)
  }

  @Test func savingAgainReplacesTheCheckpoint() async {
    defer { try? FileManager.default.removeItem(at: url) }
    let store = FileCheckpointStore(url: url)
    await store.save(night)
    let later = Night(id: night.id, start: start, end: start.addingTimeInterval(7200))
    await store.save(later)
    #expect(await store.load() == later)
  }

  @Test func nothingWhenMissingUnreadableOrCleared() async throws {
    defer { try? FileManager.default.removeItem(at: url) }
    let store = FileCheckpointStore(url: url)
    #expect(await store.load() == nil)
    try Data("not json".utf8).write(to: url)
    #expect(await store.load() == nil)
    await store.save(night)
    await store.clear()
    #expect(await store.load() == nil)
    #expect(!FileManager.default.fileExists(atPath: url.path))
  }
}
