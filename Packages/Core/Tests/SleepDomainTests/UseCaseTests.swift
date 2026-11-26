import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

struct DeleteSessionTests {
  @Test func deletesTheRecordThenItsClips() async throws {
    var withClip = Sample.event(at: 0)
    withClip.clipFileName = "a.m4a"
    var otherClip = Sample.event(at: 3600)
    otherClip.clipFileName = "b.m4a"
    let noClip = Sample.event(at: 7200, category: .sleepTalking)
    let session = Sample.night(events: [withClip, otherClip, noClip])
    let repository = FakeSessionRepository([session])
    let files = FakeSessionFileStore()

    try await DeleteSession(sessions: repository, files: files)(session.id)

    #expect(await repository.deletedIDs == [session.id])
    #expect(await repository.sessions.isEmpty)
    #expect(await Set(files.removed) == ["a.m4a", "b.m4a"])
  }

  @Test func unknownNightThrowsAndRemovesNothing() async {
    let files = FakeSessionFileStore()
    let id = UUID()
    await #expect(throws: SessionError.notFound(id)) {
      try await DeleteSession(sessions: FakeSessionRepository(), files: files)(id)
    }
    #expect(await files.removed.isEmpty)
  }

  /// The record goes first, so a failed delete keeps the clips it points at.
  @Test func failedDeleteKeepsTheClips() async throws {
    var event = Sample.event(at: 0)
    event.clipFileName = "a.m4a"
    let session = Sample.night(events: [event])
    let repository = FakeSessionRepository([session])
    let files = FakeSessionFileStore()

    struct DiskFull: Error {}
    let deleting = DeleteSession(sessions: FailingDelete(wrapping: repository), files: files)
    await #expect(throws: DiskFull.self) { try await deleting(session.id) }
    #expect(await files.removed.isEmpty)

    /// Reads succeed; delete throws.
    struct FailingDelete: SessionRepository {
      let wrapping: FakeSessionRepository
      func save(_: Night, summary _: NightSummary, scoreVersion _: String) async throws {}
      func staleNightIDs(currentVersion _: String) async throws -> [Night.ID] { [] }
      func updateStages(of _: Night.ID, stages _: [SleepStageSegment], summary _: NightSummary, scoreVersion _: String) async throws {}
      func updateSummaries(_: [NightSummary], scoreVersion _: String) async throws {}
      func session(id: Night.ID) async throws -> Night { try await wrapping.session(id: id) }
      func delete(id _: Night.ID) async throws { throw DiskFull() }
      func observeSummaries() async -> AsyncStream<[NightSummary]> { await wrapping.observeSummaries() }
      func nightFiles() async throws -> [NightFiles] { try await wrapping.nightFiles() }
      func removeClips(of id: Night.ID) async throws { try await wrapping.removeClips(of: id) }
      func deleteAll() async throws { throw DiskFull() }
    }
  }
}

struct LoadSessionDetailTests {
  private let stages = [
    SleepStageSegment(stage: .light, startOffset: 0, duration: 28800),
  ]

  @Test func returnsTheNightItsSummaryAndDisplayableEpisodes() async throws {
    let session = Sample.night(events: [
      Sample.event(at: 0, duration: 60),
      Sample.event(at: 120, duration: 60), // same episode
      Sample.event(at: 3600, duration: 1), // hidden
    ])
    let repository = FakeSessionRepository([session])

    let detail = try await LoadSessionDetail(sessions: repository)(session.id)

    #expect(detail.session == session)
    #expect(detail.summary == session.summary())
    #expect(detail.episodes.count == 1)
    #expect(await repository.savedIDs.isEmpty) // a query never writes
    #expect(await repository.stageUpdates.isEmpty)
  }

  @Test func unknownNightThrowsNotFound() async {
    let id = UUID()
    let load = LoadSessionDetail(sessions: FakeSessionRepository())
    await #expect(throws: SessionError.notFound(id)) { try await load(id) }
  }

  /// Light sleep only: −15 for missing deep and REM (see SessionMetricsTests).
  @Test func enrichingAddsMissingStagesAndStoresOnlyThemWithTheNewScore() async throws {
    let session = Sample.night(events: [Sample.event(at: 600)])
    let repository = FakeSessionRepository([session])
    let port = FakeSleepStageSource(stages: stages)

    let detail = try #require(await EnrichNightWithStages(sessions: repository, sleepStages: port)(session))

    #expect(detail.session.sleepStages == stages)
    #expect(detail.summary.score == session.summary().score - 15)
    #expect(await repository.stageUpdates == [session.id])
    #expect(await repository.savedIDs.isEmpty) // no whole-night rewrite
    #expect(await repository.sessions[session.id]?.events == session.events)
    #expect(await repository.summaries[session.id] == detail.summary)
    #expect(await repository.scoreVersions[session.id] == SleepScore.cacheVersion(for: .default))
    let request = try #require(await port.requests.first)
    #expect(request.start == session.start && request.end == session.end)
  }

  @Test func aNightWithStagesIsNotFetchedAgain() async {
    let session = Sample.night(stages: stages)
    let repository = FakeSessionRepository([session])
    let port = FakeSleepStageSource(stages: stages)

    #expect(await EnrichNightWithStages(sessions: repository, sleepStages: port)(session) == nil)
    #expect(await port.requests.isEmpty)
    #expect(await repository.stageUpdates.isEmpty)
  }

  @Test func noStagesOrAFailingSourceChangesNothing() async {
    let session = Sample.night()
    let repository = FakeSessionRepository([session])
    #expect(await EnrichNightWithStages(sessions: repository, sleepStages: FakeSleepStageSource())(session) == nil)
    #expect(await EnrichNightWithStages(sessions: repository, sleepStages: FakeSleepStageSource(fails: true))(session) == nil)
    #expect(await repository.stageUpdates.isEmpty)
  }

  /// The screen still shows the stages; the store keeps the night without
  /// them, so the next open tries again.
  @Test func aFailedStoreStillReturnsTheStages() async throws {
    struct DiskFull: Error {}
    let session = Sample.night()
    let repository = FakeSessionRepository([session])
    await repository.failNextCall(with: DiskFull())

    let detail = try #require(
      await EnrichNightWithStages(sessions: repository, sleepStages: FakeSleepStageSource(stages: stages))(session))

    #expect(detail.session.sleepStages == stages)
    #expect(await repository.sessions[session.id]?.sleepStages.isEmpty == true)
  }
}

struct FakeSessionRepositoryTests {
  /// Observers get the current list first, then every change, newest night first.
  @Test func observeSummariesYieldsCurrentThenChanges() async throws {
    let older = Sample.night()
    let newer = Night(start: Sample.at(86400), end: Sample.at(86400 + 3600))
    let repository = FakeSessionRepository([older])
    var updates = await repository.observeSummaries().makeAsyncIterator()

    #expect(await updates.next()?.map(\.id) == [older.id])
    try await repository.save(newer, summary: newer.summary(), scoreVersion: "")
    #expect(await updates.next()?.map(\.id) == [newer.id, older.id])
    try await repository.delete(id: older.id)
    #expect(await updates.next()?.map(\.id) == [newer.id])
  }
}
