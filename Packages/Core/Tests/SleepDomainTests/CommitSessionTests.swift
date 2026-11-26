import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

struct CommitSessionTests {
  @Test func savesTheNightWithItsSummaryThenClearsItsCheckpoint() async throws {
    let night = Sample.night(events: [Sample.event(at: 3600), Sample.event(at: 7200)])
    let repository = FakeSessionRepository()
    let checkpoints = FakeRecordingCheckpointStore(night)

    try await CommitSession(sessions: repository, checkpoints: checkpoints)(night)

    #expect(await repository.savedIDs == [night.id])
    #expect(await repository.sessions[night.id] == night)
    #expect(await repository.summaries[night.id] == night.summary())
    #expect(await checkpoints.night == nil)
  }

  @Test func refusesANightUnderTheMinimum() async {
    let night = Sample.night(hours: (SaveRules.standard.minimumDuration - 1) / 3600)
    let repository = FakeSessionRepository()
    let checkpoints = FakeRecordingCheckpointStore(night)
    await #expect(throws: CommitSession.Failure.tooShort) {
      try await CommitSession(sessions: repository, checkpoints: checkpoints)(night)
    }
    #expect(await repository.savedIDs.isEmpty)
    #expect(await checkpoints.night == night)
  }

  /// The checkpoint outlives a failed save: the night can still be recovered.
  @Test func aStoreFailureIsThrownAndKeepsTheCheckpoint() async {
    struct Broken: Error {}
    let night = Sample.night()
    let repository = FakeSessionRepository()
    await repository.failNextCall(with: Broken())
    let checkpoints = FakeRecordingCheckpointStore(night)
    await #expect(throws: Broken.self) {
      try await CommitSession(sessions: repository, checkpoints: checkpoints)(night)
    }
    #expect(await checkpoints.clears == 0)
  }
}

struct RecoveryTests {
  @Test func aNightWithEventsIsOfferedAndKept() async {
    let night = Sample.night(events: [Sample.event(at: 600)])
    let checkpoints = FakeRecordingCheckpointStore(night)
    let files = FakeSessionFileStore()
    #expect(await RecoverInterruptedSession(checkpoints: checkpoints, files: files)() == night)
    #expect(await checkpoints.night == night)
  }

  /// SleepGuard's rule: a night without events isn't worth asking about.
  @Test func aNightWithoutEventsIsClearedSilently() async {
    let checkpoints = FakeRecordingCheckpointStore(Sample.night())
    let files = FakeSessionFileStore()
    #expect(await RecoverInterruptedSession(checkpoints: checkpoints, files: files)() == nil)
    #expect(await checkpoints.night == nil)
  }

  @Test func nothingToRecover() async {
    let checkpoints = FakeRecordingCheckpointStore()
    #expect(await RecoverInterruptedSession(checkpoints: checkpoints, files: FakeSessionFileStore())() == nil)
    #expect(await checkpoints.clears == 0)
  }

  @Test func discardRemovesTheClipsAndTheCheckpoint() async {
    var withClip = Sample.event(at: 0)
    withClip.clipFileName = "a.m4a"
    let night = Sample.night(events: [withClip, Sample.event(at: 600)])
    let checkpoints = FakeRecordingCheckpointStore(night)
    let files = FakeSessionFileStore()
    await DiscardRecording(checkpoints: checkpoints, files: files)(night)
    #expect(await files.removed == ["a.m4a"])
    #expect(await checkpoints.night == nil)
  }

  @Test func discardWithNoNightClearsTheCheckpoint() async {
    let checkpoints = FakeRecordingCheckpointStore(Sample.night())
    let files = FakeSessionFileStore()
    await DiscardRecording(checkpoints: checkpoints, files: files)(nil)
    #expect(await files.removed.isEmpty)
    #expect(await checkpoints.clears == 1)
  }
}
