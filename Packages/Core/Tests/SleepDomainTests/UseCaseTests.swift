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
      func save(_: Night, summary _: NightSummary) async throws {}
      func session(id: Night.ID) async throws -> Night { try await wrapping.session(id: id) }
      func delete(id _: Night.ID) async throws { throw DiskFull() }
      func observeSummaries() async -> AsyncStream<[NightSummary]> { await wrapping.observeSummaries() }
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
    let load = LoadSessionDetail(sessions: FakeSessionRepository([session]), sleepStages: FakeSleepStagePort())

    let detail = try await load(session.id)

    #expect(detail.session == session)
    #expect(detail.summary == session.summary())
    #expect(detail.episodes.count == 1)
  }

  /// Light sleep only: −15 for missing deep and REM (see SessionMetricsTests).
  @Test func addsMissingStagesAndSavesTheNewScore() async throws {
    let session = Sample.night()
    let repository = FakeSessionRepository([session])
    let port = FakeSleepStagePort(stages: stages)

    let detail = try await LoadSessionDetail(sessions: repository, sleepStages: port)(session.id)

    #expect(detail.session.sleepStages == stages)
    #expect(detail.summary.score == 85)
    #expect(await repository.savedIDs == [session.id])
    #expect(await repository.summaries[session.id]?.score == 85)
    let request = try #require(await port.requests.first)
    #expect(request.start == session.start && request.end == session.end)
  }

  @Test func nightWithStagesIsNotFetchedAgain() async throws {
    let session = Sample.night(stages: stages)
    let repository = FakeSessionRepository([session])
    let port = FakeSleepStagePort(stages: stages)

    _ = try await LoadSessionDetail(sessions: repository, sleepStages: port)(session.id)

    #expect(await port.requests.isEmpty)
    #expect(await repository.savedIDs.isEmpty)
  }

  @Test func noStagesAvailableChangesNothing() async throws {
    let session = Sample.night()
    let repository = FakeSessionRepository([session])

    let detail = try await LoadSessionDetail(sessions: repository, sleepStages: FakeSleepStagePort())(session.id)

    #expect(detail.summary.score == 100)
    #expect(await repository.savedIDs.isEmpty)
  }

  @Test func failingStageSourceStillOpensTheNight() async throws {
    let session = Sample.night()
    let load = LoadSessionDetail(
      sessions: FakeSessionRepository([session]),
      sleepStages: FakeSleepStagePort(fails: true))
    #expect(try await load(session.id).session == session)
  }

  @Test func unknownNightThrowsNotFound() async {
    let id = UUID()
    let load = LoadSessionDetail(sessions: FakeSessionRepository(), sleepStages: FakeSleepStagePort())
    await #expect(throws: SessionError.notFound(id)) { try await load(id) }
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
    try await repository.save(newer, summary: newer.summary())
    #expect(await updates.next()?.map(\.id) == [newer.id, older.id])
    try await repository.delete(id: older.id)
    #expect(await updates.next()?.map(\.id) == [newer.id])
  }
}
