import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

/// The storage limits remove the chosen nights' audio and the files no night
/// refers to; delete all empties every store; a saved night reaches Apple
/// Health only when that's on; a raw recording is kept only when asked.
struct EnforceStorageLimitsTests {
  private static let megabyte: Int64 = 1_024 * 1_024
  private static let now = Sample.start.addingTimeInterval(30 * 24 * 3600)

  private static func night(daysAgo: Double, clip: String) -> Night {
    let start = now.addingTimeInterval(-daysAgo * 24 * 3600)
    var event = NightEvent(start: start.addingTimeInterval(600), duration: 60, intensity: .light)
    event.clipFileName = clip
    return Night(start: start, end: start.addingTimeInterval(8 * 3600), events: [event])
  }

  private static func limits(days: Int? = nil, megabytes: Int? = nil) -> FakePreferencesStore {
    var preferences = AppPreferences()
    preferences.limitDays = days != nil
    preferences.maxDays = days ?? 30
    preferences.limitStorage = megabytes != nil
    preferences.storageLimitMB = megabytes ?? 500
    return FakePreferencesStore(preferences)
  }

  private static func enforce(
    _ nights: [Night], files: FakeSessionFileStore, preferences: FakePreferencesStore,
    checkpoint: Night? = nil) async throws -> (EnforceStorageLimits.Report, FakeSessionRepository)
  {
    let repository = FakeSessionRepository(nights)
    let report = try await EnforceStorageLimits(
      sessions: repository, files: files, checkpoints: FakeRecordingCheckpointStore(checkpoint),
      preferences: preferences, now: { now })()
    return (report, repository)
  }

  @Test func theDayLimitTakesOldNightsAudioAndKeepsTheNights() async throws {
    let old = Self.night(daysAgo: 10, clip: "old.m4a")
    let recent = Self.night(daysAgo: 1, clip: "recent.m4a")
    let raw = RawRecording.logFileName(for: old.id)
    let files = FakeSessionFileStore(files: ["old.m4a": 1_000, raw: 500, "recent.m4a": 1_000])

    let (report, repository) = try await Self.enforce([old, recent], files: files, preferences: Self.limits(days: 7))

    #expect(report.dayLimitNights == 1 && report.sizeLimitNights == 0)
    #expect(report.filesRemoved == 2 && report.bytesRemoved == 1_500)
    #expect(await files.files.keys.sorted() == ["recent.m4a"])
    #expect(try await repository.session(id: old.id).events.first?.clipFileName == nil)
    #expect(try await repository.session(id: recent.id).events.first?.clipFileName == "recent.m4a")
  }

  @Test func theSizeLimitTakesTheOldestUntilUnder() async throws {
    let nights = [3.0, 2, 1].enumerated().map { Self.night(daysAgo: $1, clip: "\($0).m4a") }
    let files = FakeSessionFileStore(files: ["0.m4a": Self.megabyte, "1.m4a": Self.megabyte, "2.m4a": Self.megabyte])

    let (report, _) = try await Self.enforce(nights, files: files, preferences: Self.limits(megabytes: 2))

    #expect(report.sizeLimitNights == 1)
    #expect(await files.files.keys.sorted() == ["1.m4a", "2.m4a"])
  }

  @Test func filesNoNightRefersToGoButTheCheckpointsStay() async throws {
    let saved = Self.night(daysAgo: 1, clip: "saved.m4a")
    let inProgress = Self.night(daysAgo: 0, clip: "open.caf")
    let files = FakeSessionFileStore(files: [
      "saved.m4a": 10, "open.caf": 10, "crashed.caf": 30,
      RawRecording.audioFileName(for: inProgress.id): 10,
    ])

    let (report, _) = try await Self.enforce(
      [saved], files: files, preferences: Self.limits(), checkpoint: inProgress)

    #expect(report.leftoverFiles == 1 && report.bytesRemoved == 30)
    #expect(await files.removed == ["crashed.caf"])
  }

  @Test func noLimitsAndNoLeftoversChangeNothing() async throws {
    let night = Self.night(daysAgo: 400, clip: "a.m4a")
    let files = FakeSessionFileStore(files: ["a.m4a": Self.megabyte])

    let (report, _) = try await Self.enforce([night], files: files, preferences: Self.limits())

    #expect(report == EnforceStorageLimits.Report())
    #expect(await files.removed.isEmpty)
  }
}

struct DeleteAllDataTests {
  @Test func removesEveryNightFileAndTheCheckpoint() async throws {
    let repository = FakeSessionRepository([Sample.night()])
    let files = FakeSessionFileStore(files: ["a.m4a": 1, "rawlog_x.jsonl": 1])
    let checkpoints = FakeRecordingCheckpointStore(Sample.night())

    try await DeleteAllData(sessions: repository, files: files, checkpoints: checkpoints)()

    #expect(await repository.sessions.isEmpty)
    #expect(await files.files.isEmpty)
    #expect(await checkpoints.night == nil)
  }

  @Test func aStoreFailureLeavesTheFiles() async {
    struct Broken: Error {}
    let repository = FakeSessionRepository([Sample.night()])
    await repository.failNextCall(with: Broken())
    let files = FakeSessionFileStore(files: ["a.m4a": 1])
    await #expect(throws: Broken.self) {
      try await DeleteAllData(sessions: repository, files: files, checkpoints: FakeRecordingCheckpointStore())()
    }
    #expect(await files.files.count == 1)
  }
}

struct CommitSessionHealthTests {
  @Test(arguments: [true, false])
  func theNightReachesHealthOnlyWhenSyncIsOn(sync: Bool) async throws {
    var preferences = AppPreferences()
    preferences.syncToHealth = sync
    let health = FakeHealthAccess()
    let night = Sample.night()

    try await CommitSession(
      sessions: FakeSessionRepository(), checkpoints: FakeRecordingCheckpointStore(),
      health: health, preferences: FakePreferencesStore(preferences))(night)

    #expect(await health.saved == (sync ? [night.id] : []))
  }
}

struct RawRecordingTests {
  @Test @MainActor
  func preserveRawAudioKeepsTheAudioAndEverySample() async throws {
    let capture = FakeAudioCapture()
    let log = FakeRawLogWriter()
    let session = RecordingSession(
      capture: capture, settings: .init(sensitivity: .high, detectSleepTalking: true, preserveRawAudio: true),
      rawLog: log, start: Sample.start)
    _ = try await session.start()
    for tick in 1...50 {
      await session.receive(Harness.sample(at: Double(tick) * 0.05, db: -40, snore: 0, speech: 0))
    }
    let draft = await session.stop(at: Sample.at(3))

    #expect(capture.rawAudioFileName == RawRecording.audioFileName(for: draft.id))
    #expect(await log.night == draft.id)
    #expect(await log.metadata?.detectionSensitivity == "high")
    #expect(await log.samples.count == 50)
    #expect(await abs((log.samples.first?.elapsed ?? 0) - 0.05) < 0.001)
    #expect(await log.finished)
  }

  @Test @MainActor
  func withoutItNothingIsKept() async throws {
    let capture = FakeAudioCapture()
    let log = FakeRawLogWriter()
    let session = RecordingSession(capture: capture, rawLog: log, start: Sample.start)
    _ = try await session.start()
    _ = await session.stop(at: Sample.at(1))

    #expect(capture.rawAudioFileName == nil)
    #expect(await log.night == nil)
  }
}
