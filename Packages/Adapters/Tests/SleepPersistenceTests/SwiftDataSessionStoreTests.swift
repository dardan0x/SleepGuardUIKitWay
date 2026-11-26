import Foundation
import SleepCore
import SleepDomain
import SwiftData
import Testing
@testable import SleepPersistence

/// Against a real SwiftData store (in memory, or on disk for reopening).
struct SwiftDataSessionStoreTests {
  private let start = Date(timeIntervalSinceReferenceDate: 23 * 3600)

  private func event(at seconds: TimeInterval, category: SoundCategory = .snoring, clip: String? = nil) -> NightEvent {
    NightEvent(
      start: start.addingTimeInterval(seconds), duration: 60, category: category, intensity: .loud,
      averageDB: -30, peakDB: -20, averageConfidence: 0.8,
      bursts: [SnoreBurst(startOffset: 0, endOffset: 20), SnoreBurst(startOffset: 30, endOffset: 55)],
      clipFileName: clip)
  }

  private func night(events: [NightEvent] = [], startOffset: TimeInterval = 0) -> Night {
    Night(
      start: start.addingTimeInterval(startOffset), end: start.addingTimeInterval(startOffset + 8 * 3600),
      averageDB: -42, peakDB: -12, events: events,
      recordingGaps: [RecordingGap(startOffset: 600, duration: 30, snoringResumed: false)],
      sleepStages: [SleepStageSegment(stage: .deep, startOffset: 0, duration: 3600)],
      endReason: .lowBattery)
  }

  private func makeStore() throws -> (SwiftDataSessionStore, ModelContainer) {
    let container = try PersistenceSchema.container(at: nil)
    return (SwiftDataSessionStore(modelContainer: container), container)
  }

  private func eventRecordCount(_ container: ModelContainer) throws -> Int {
    try ModelContext(container).fetchCount(FetchDescriptor<EventRecord>())
  }

  @Test func savedNightComesBackEqual() async throws {
    let (store, _) = try makeStore()
    let session = night(events: [event(at: 0, clip: "a.m4a"), event(at: 600, category: .sleepTalking)])
    try await store.save(session, summary: session.summary(), scoreVersion: "v")
    #expect(try await store.session(id: session.id) == session)
  }

  @Test func eventsComeBackInTimeOrder() async throws {
    let (store, _) = try makeStore()
    let late = event(at: 7200)
    let early = event(at: 0)
    let session = night(events: [late, early])
    try await store.save(session, summary: session.summary(), scoreVersion: "v")
    #expect(try await store.session(id: session.id).events.map(\.id) == [early.id, late.id])
  }

  @Test func savingAgainReplacesTheNightAndItsEvents() async throws {
    let (store, container) = try makeStore()
    var session = night(events: [event(at: 0), event(at: 600), event(at: 1200)])
    try await store.save(session, summary: session.summary(), scoreVersion: "v")

    session.events = [event(at: 3600)]
    session.sleepStages = []
    try await store.save(session, summary: session.summary(), scoreVersion: "v")

    #expect(try await store.session(id: session.id) == session)
    #expect(try eventRecordCount(container) == 1) // the three old events are gone
  }

  @Test func deleteRemovesTheNightAndItsEvents() async throws {
    let (store, container) = try makeStore()
    let session = night(events: [event(at: 0), event(at: 600)])
    try await store.save(session, summary: session.summary(), scoreVersion: "v")

    try await store.delete(id: session.id)

    await #expect(throws: SessionError.notFound(session.id)) { try await store.session(id: session.id) }
    #expect(try eventRecordCount(container) == 0)
  }

  @Test func unknownNightThrowsNotFound() async throws {
    let (store, _) = try makeStore()
    let id = UUID()
    await #expect(throws: SessionError.notFound(id)) { try await store.session(id: id) }
    await #expect(throws: SessionError.notFound(id)) { try await store.delete(id: id) }
  }

  /// Observers get the stored summaries, newest night first, then every change.
  @Test func observeSummariesYieldsCurrentThenChanges() async throws {
    let (store, _) = try makeStore()
    let older = night(events: [event(at: 0)])
    try await store.save(older, summary: older.summary(), scoreVersion: "v")
    var updates = await store.observeSummaries().makeAsyncIterator()

    #expect(await updates.next() == [older.summary()])
    #expect(older.summary().loudestIntensity != nil) // the stored summary keeps it

    let newer = night(startOffset: 86400)
    try await store.save(newer, summary: newer.summary(), scoreVersion: "v")
    #expect(await updates.next()?.map(\.id) == [newer.id, older.id])

    try await store.delete(id: older.id)
    #expect(await updates.next()?.map(\.id) == [newer.id])
  }

  @Test func nightsSurviveReopeningTheStore() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("nights.store")
    let session = night(events: [event(at: 0, clip: "a.m4a")])

    try await SleepPersistence.makeSessionRepository(storeURL: url).save(session, summary: session.summary(), scoreVersion: "v")
    let reopened = try SleepPersistence.makeSessionRepository(storeURL: url)

    #expect(try await reopened.session(id: session.id) == session)
  }

  /// A value written by a newer version reads as the safest default.
  @Test func unknownStoredValuesReadAsDefaults() async throws {
    let (store, container) = try makeStore()
    let session = night(events: [event(at: 0)])
    try await store.save(session, summary: session.summary(), scoreVersion: "v")

    let context = ModelContext(container)
    let record = try #require(try context.fetch(FetchDescriptor<EventRecord>()).first)
    record.category = "laughing"
    record.intensity = "thunderous"
    try context.save()

    let loaded = try await store.session(id: session.id).events[0]
    #expect(loaded.category == .other)
    #expect(loaded.intensity == .quiet)
  }
}

struct FileSessionStoreTests {
  @Test func removesNamedFilesIgnoresMissingAndStaysInItsDirectory() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let clips = root.appendingPathComponent("Clips", isDirectory: true)
    try FileManager.default.createDirectory(at: clips, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    for name in ["a.m4a", "b.m4a"] {
      try Data([1]).write(to: clips.appendingPathComponent(name))
    }
    let outside = root.appendingPathComponent("keep.txt")
    try Data([1]).write(to: outside)

    await SleepPersistence.makeSessionFileStore(directory: clips)
      .removeFiles(named: ["a.m4a", "missing.m4a", "../keep.txt"])

    let left = try FileManager.default.contentsOfDirectory(atPath: clips.path)
    #expect(left == ["b.m4a"])
    #expect(FileManager.default.fileExists(atPath: outside.path))
  }

  @Test func servesOnlyExistingFilesInItsDirectory() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let clips = root.appendingPathComponent("Clips", isDirectory: true)
    try FileManager.default.createDirectory(at: clips, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try Data([1]).write(to: clips.appendingPathComponent("a.m4a"))
    try Data([1]).write(to: root.appendingPathComponent("keep.txt"))

    let store = SleepPersistence.makeSessionFileStore(directory: clips)
    #expect(store.url(forFileNamed: "a.m4a")?.lastPathComponent == "a.m4a")
    #expect(store.url(forFileNamed: "missing.m4a") == nil)
    #expect(store.url(forFileNamed: "../keep.txt") == nil)
    #expect(store.url(forFileNamed: "") == nil)
  }
}

/// Score versions (F13-T2).
extension SwiftDataSessionStoreTests {
  @Test func nightsFromAnotherScoreVersionAreStale() async throws {
    let (store, _) = try makeStore()
    let current = night()
    let old = night(startOffset: -86400)
    let unversioned = night(startOffset: -2 * 86400)
    try await store.save(current, summary: current.summary(), scoreVersion: "2-a")
    try await store.save(old, summary: old.summary(), scoreVersion: "1-a")
    try await store.save(unversioned, summary: unversioned.summary(), scoreVersion: "")

    #expect(try await store.staleNightIDs(currentVersion: "2-a") == [unversioned.id, old.id]) // oldest first
  }

  @Test func updatingSummariesKeepsEventsAndStampsTheVersion() async throws {
    let (store, container) = try makeStore()
    let session = night(events: [event(at: 0, clip: "a.m4a")])
    try await store.save(session, summary: session.summary(), scoreVersion: "1-a")
    let eventID = try ModelContext(container).fetch(FetchDescriptor<EventRecord>()).first?.persistentModelID
    var newer = session.summary()
    newer = NightSummary(
      id: newer.id, start: newer.start, end: newer.end, score: 42, snoringDuration: newer.snoringDuration,
      eventCount: newer.eventCount, loudestIntensity: newer.loudestIntensity)

    try await store.updateSummaries([newer, night(startOffset: 86400).summary()], scoreVersion: "2-a") // second is unknown

    var summaries: [NightSummary] = []
    for await current in await store.observeSummaries() {
      summaries = current
      break
    }
    #expect(summaries.map(\.score) == [42])
    #expect(try await store.staleNightIDs(currentVersion: "2-a").isEmpty)
    #expect(try await store.session(id: session.id) == session)
    #expect(try ModelContext(container).fetch(FetchDescriptor<EventRecord>()).first?.persistentModelID == eventID)
  }

  // F13-T3: stages are a narrow write, not a whole-night rewrite.
  @Test func updatingStagesKeepsTheStoredEvents() async throws {
    let (store, container) = try makeStore()
    var session = night(events: [event(at: 0, clip: "a.m4a"), event(at: 600)])
    session.sleepStages = []
    try await store.save(session, summary: session.summary(), scoreVersion: "1-a")
    let before = try Set(ModelContext(container).fetch(FetchDescriptor<EventRecord>()).map(\.persistentModelID))
    let stages = [SleepStageSegment(stage: .rem, startOffset: 0, duration: 1800)]
    session.sleepStages = stages

    try await store.updateStages(of: session.id, stages: stages, summary: session.summary(), scoreVersion: "2-a")

    let after = try Set(ModelContext(container).fetch(FetchDescriptor<EventRecord>()).map(\.persistentModelID))
    #expect(after == before)
    #expect(try await store.session(id: session.id) == session)
    #expect(try await store.staleNightIDs(currentVersion: "2-a").isEmpty)
    await #expect(throws: SessionError.notFound(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)) {
      try await store.updateStages(
        of: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, stages: stages, summary: session.summary(),
        scoreVersion: "2-a")
    }
  }

  // F13-T4: every write reaches observers, the narrow ones included.
  @Test func everyKindOfWriteReachesObservers() async throws {
    let (store, _) = try makeStore()
    let first = night(events: [event(at: 0, clip: "a.m4a")])
    let second = night(startOffset: 86400)
    var updates = await store.observeSummaries().makeAsyncIterator()
    #expect(await updates.next() == []) // the current list

    try await store.save(first, summary: first.summary(), scoreVersion: "1")
    #expect(await updates.next()?.map(\.id) == [first.id])
    try await store.save(second, summary: second.summary(), scoreVersion: "1")
    #expect(await updates.next()?.map(\.id) == [second.id, first.id])

    try await store.updateStages(of: first.id, stages: [], summary: first.summary(), scoreVersion: "2")
    #expect(await updates.next()?.count == 2)
    try await store.updateSummaries([second.summary()], scoreVersion: "2")
    #expect(await updates.next()?.count == 2)
    try await store.removeClips(of: first.id)
    #expect(await updates.next()?.count == 2)
    try await store.delete(id: second.id)
    #expect(await updates.next()?.map(\.id) == [first.id])
    try await store.deleteAll()
    #expect(await updates.next() == [])
  }
}
