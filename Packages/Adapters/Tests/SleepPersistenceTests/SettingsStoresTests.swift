import Foundation
import SleepCore
import SleepDomain
import Testing
@testable import SleepPersistence

/// Preferences and the profile come back as saved; a raw log reads back
/// through SleepCore's `RawLog`; the file store and the repository answer
/// the storage limits' questions.
struct SettingsStoresTests {
  private let directory: URL = {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }()

  @Test func preferencesStartAtTheDefaultsAndComeBackAsSaved() async throws {
    let suite = "settings-test-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = SleepPersistence.makePreferencesStore(suiteName: suite)
    #expect(await store.load() == AppPreferences())

    var changed = AppPreferences()
    changed.sensitivity = .high
    changed.detectSleepTalking = true
    changed.recordingDelayMinutes = 30
    changed.limitStorage = false
    changed.storageLimitMB = 1000
    changed.maxDays = 7
    changed.syncToHealth = true
    changed.briefingEnabled = false
    await store.save(changed)

    #expect(await store.load() == changed)
  }

  @Test func anUnknownDelayReadsAsOff() async throws {
    let suite = "settings-test-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(20, forKey: "recordingDelayMinutes")
    #expect(await SleepPersistence.makePreferencesStore(suiteName: suite).load().recordingDelayMinutes == 0)
  }

  @Test func theProfileComesBackAndClears() async throws {
    let store = SleepPersistence.makeProfileStore(url: directory.appendingPathComponent("Profile.json"))
    #expect(await store.load() == SleepProfile())
    let profile = SleepProfile(firstName: "Sam", birthYear: 1990, goal: .snoreLess, hobbies: ["reading"])
    try await store.save(profile)
    #expect(await store.load() == profile)
    await store.clear()
    #expect(await store.load() == SleepProfile())
  }

  @Test func theRawLogIsSleepCoresFormat() async throws {
    let night = UUID()
    let writer = SleepPersistence.makeRawLogWriter(directory: directory)
    let metadata = RawLogMetadata(
      sessionStart: Date(timeIntervalSinceReferenceDate: 0), detectionSensitivity: "medium",
      detectSleepTalking: false, snoreInterrupterMode: "never")
    await writer.begin(night: night, metadata: metadata)
    let samples = (1...3).map {
      SnoreSample(elapsed: Double($0) * 0.05, db: -40, spectralScore: 0, snoreConfidence: 0.1, state: .none)
    }
    await writer.append(Array(samples.prefix(2)))
    await writer.append(Array(samples.suffix(1)))
    await writer.finish()

    let data = try Data(contentsOf: directory.appendingPathComponent(RawRecording.logFileName(for: night)))
    let log = try RawLog.decode(from: data)
    #expect(log.metadata == metadata)
    #expect(log.samples.count == 3)
  }

  @Test func theFileStoreKnowsItsFilesAndTheirSizes() async throws {
    try Data(count: 1_234).write(to: directory.appendingPathComponent("a.m4a"))
    let store = SleepPersistence.makeSessionFileStore(directory: directory)
    #expect(await store.allFileNames() == ["a.m4a"])
    #expect(await store.size(ofFileNamed: "a.m4a") == 1_234)
    #expect(await store.size(ofFileNamed: "missing.m4a") == 0)
    #expect(await store.size(ofFileNamed: "../a.m4a") == 0)
  }

  @Test func theRepositoryListsFilesForgetsClipsAndDeletesAll() async throws {
    let repository = try SleepPersistence.makeSessionRepository(storeURL: nil)
    let start = Date(timeIntervalSinceReferenceDate: 23 * 3600)
    let night = Night(
      start: start, end: start.addingTimeInterval(8 * 3600),
      events: [NightEvent(start: start, duration: 60, intensity: .light, clipFileName: "a.m4a")])
    try await repository.save(night, summary: night.summary())

    #expect(try await repository.nightFiles() == [NightFiles(id: night.id, start: start, clipFileNames: ["a.m4a"])])
    try await repository.removeClips(of: night.id)
    #expect(try await repository.session(id: night.id).events.count == 1)
    #expect(try await repository.nightFiles().first?.clipFileNames == [])

    try await repository.deleteAll()
    #expect(try await repository.nightFiles().isEmpty)
  }
}
