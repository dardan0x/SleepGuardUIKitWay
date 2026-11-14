import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

struct DeleteSessionTests {
  @Test func deletesTheRecordThenItsClips() async throws {
    var withClip = Night.event(at: 0)
    withClip.clipFileName = "a.m4a"
    var otherClip = Night.event(at: 3600)
    otherClip.clipFileName = "b.m4a"
    let noClip = Night.event(at: 7200, category: .sleepTalking)
    let session = Night.session(events: [withClip, otherClip, noClip])
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
    var event = Night.event(at: 0)
    event.clipFileName = "a.m4a"
    let session = Night.session(events: [event])
    let repository = FakeSessionRepository([session])
    let files = FakeSessionFileStore()

    struct DiskFull: Error {}
    let deleting = DeleteSession(sessions: FailingDelete(wrapping: repository), files: files)
    await #expect(throws: DiskFull.self) { try await deleting(session.id) }
    #expect(await files.removed.isEmpty)

    /// Reads succeed; delete throws.
    struct FailingDelete: SessionRepository {
      let wrapping: FakeSessionRepository
      func save(_: SleepSession, summary _: SessionSummary) async throws {}
      func session(id: SleepSession.ID) async throws -> SleepSession { try await wrapping.session(id: id) }
      func delete(id _: SleepSession.ID) async throws { throw DiskFull() }
      func observeSummaries() async -> AsyncStream<[SessionSummary]> { await wrapping.observeSummaries() }
    }
  }
}

struct LoadSessionDetailTests {
  private let stages = [
    SleepStageSegment(stage: .light, startOffset: 0, duration: 28800),
  ]

  @Test func returnsTheNightItsSummaryAndDisplayableEpisodes() async throws {
    let session = Night.session(events: [
      Night.event(at: 0, duration: 60),
      Night.event(at: 120, duration: 60), // same episode
      Night.event(at: 3600, duration: 1), // hidden
    ])
    let load = LoadSessionDetail(sessions: FakeSessionRepository([session]), sleepStages: FakeSleepStagePort())

    let detail = try await load(session.id)

    #expect(detail.session == session)
    #expect(detail.summary == session.summary())
    #expect(detail.episodes.count == 1)
  }

  /// Light sleep only: −15 for missing deep and REM (see SessionMetricsTests).
  @Test func addsMissingStagesAndSavesTheNewScore() async throws {
    let session = Night.session()
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
    let session = Night.session(stages: stages)
    let repository = FakeSessionRepository([session])
    let port = FakeSleepStagePort(stages: stages)

    _ = try await LoadSessionDetail(sessions: repository, sleepStages: port)(session.id)

    #expect(await port.requests.isEmpty)
    #expect(await repository.savedIDs.isEmpty)
  }

  @Test func noStagesAvailableChangesNothing() async throws {
    let session = Night.session()
    let repository = FakeSessionRepository([session])

    let detail = try await LoadSessionDetail(sessions: repository, sleepStages: FakeSleepStagePort())(session.id)

    #expect(detail.summary.score == 100)
    #expect(await repository.savedIDs.isEmpty)
  }

  @Test func failingStageSourceStillOpensTheNight() async throws {
    let session = Night.session()
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
    let older = Night.session()
    let newer = SleepSession(start: Night.at(86400), end: Night.at(86400 + 3600))
    let repository = FakeSessionRepository([older])
    var updates = await repository.observeSummaries().makeAsyncIterator()

    #expect(await updates.next()?.map(\.id) == [older.id])
    try await repository.save(newer, summary: newer.summary())
    #expect(await updates.next()?.map(\.id) == [newer.id, older.id])
    try await repository.delete(id: older.id)
    #expect(await updates.next()?.map(\.id) == [newer.id])
  }
}
