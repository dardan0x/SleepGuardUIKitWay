import Foundation
import SleepCore
import SleepDomain

/// What every implementation of a port with state must do: the adapter and
/// its fake both run these, so a fake can't drift from the real thing (a test
/// that passes on the fake then means the same on the device).
///
/// Each check returns its violations, one line each, so this module needs no
/// test framework: a test expects `[]`. Pass a factory that makes a fresh,
/// empty store each call.
///
/// Fakes for ports whose job is an effect (players, the capture, Health) are
/// spies: they record calls rather than hold state, so they have no contract.
public enum PortContracts {
  // MARK: - SessionRepository

  public static func sessionRepository(_ make: () async throws -> any SessionRepository) async -> [String] {
    var violations: [String] = []
    func check(_ condition: Bool, _ message: String) {
      if !condition { violations.append("SessionRepository: \(message)") }
    }
    do {
      let store = try await make()
      let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
      let unknown = UUID()

      await check(first(store.observeSummaries()) == [], "an empty store lists no summaries")
      try await check(store.nightFiles().isEmpty, "an empty store has no files")
      await check(throwsNotFound(unknown) { _ = try await store.session(id: unknown) }, "session(id:) of an unknown night throws notFound")
      await check(throwsNotFound(unknown) { try await store.delete(id: unknown) }, "delete of an unknown night throws notFound")
      await check(throwsNotFound(unknown) { try await store.removeClips(of: unknown) }, "removeClips of an unknown night throws notFound")
      let anySummary = Night(start: start, end: start.addingTimeInterval(60)).summary()
      await check(
        throwsNotFound(unknown) { try await store.updateStages(of: unknown, stages: [], summary: anySummary, scoreVersion: "1") },
        "updateStages of an unknown night throws notFound")

      // Events saved out of order come back in time order.
      let late = NightEvent(start: start.addingTimeInterval(7200), duration: 60, intensity: .loud, clipFileName: "late.m4a")
      let early = NightEvent(start: start.addingTimeInterval(600), duration: 30, intensity: .light, clipFileName: "early.m4a")
      let older = Night(start: start, end: start.addingTimeInterval(8 * 3600), events: [late, early])
      let newer = Night(start: start.addingTimeInterval(86400), end: start.addingTimeInterval(86400 + 7 * 3600))
      try await store.save(older, summary: older.summary(), scoreVersion: "1")
      try await store.save(newer, summary: newer.summary(), scoreVersion: "2")
      let loaded = try await store.session(id: older.id)
      check(loaded.events.map(\.id) == [early.id, late.id], "a night's events come back in time order")
      check(loaded.events == older.events.sorted { $0.start < $1.start } && loaded.start == older.start, "a saved night comes back equal")
      await check(first(store.observeSummaries())?.map(\.id) == [newer.id, older.id], "summaries are newest first")
      try await check(store.nightFiles().map(\.id) == [older.id, newer.id], "night files are oldest first")
      try await check(
        Set(store.nightFiles().first?.clipFileNames ?? []) == ["early.m4a", "late.m4a"],
        "night files list the clips")

      // Score versions.
      try await check(store.staleNightIDs(currentVersion: "2") == [older.id], "nights from another score version are stale")
      var rescored = older.summary()
      rescored = NightSummary(
        id: rescored.id, start: rescored.start, end: rescored.end, score: 42, snoringDuration: rescored.snoringDuration,
        eventCount: rescored.eventCount, loudestIntensity: rescored.loudestIntensity)
      try await store.updateSummaries([rescored, anySummary], scoreVersion: "2")
      try await check(store.staleNightIDs(currentVersion: "2").isEmpty, "updateSummaries stamps the version")
      await check(
        first(store.observeSummaries())?.first { $0.id == older.id }?.score == 42,
        "updateSummaries replaces the summary")
      try await check(store.session(id: older.id).events.count == 2, "updateSummaries keeps the events")

      // Stages.
      let stages = [SleepStageSegment(stage: .deep, startOffset: 0, duration: 3600)]
      try await store.updateStages(of: older.id, stages: stages, summary: older.summary(), scoreVersion: "3")
      let staged = try await store.session(id: older.id)
      check(staged.sleepStages == stages, "updateStages sets the stages")
      check(staged.events == older.events.sorted { $0.start < $1.start }, "updateStages keeps the events")

      // Clips, then deletion.
      try await store.removeClips(of: older.id)
      let clipless = try await store.session(id: older.id)
      check(clipless.events.allSatisfy { $0.clipFileName == nil }, "removeClips forgets every clip")
      check(clipless.events.map(\.duration) == [30, 60], "removeClips keeps the rest of each event")
      try await store.delete(id: newer.id)
      await check(first(store.observeSummaries())?.map(\.id) == [older.id], "a deleted night leaves the list")
      await check(throwsNotFound(newer.id) { _ = try await store.session(id: newer.id) }, "a deleted night is not found")
      // Several at once: all or none.
      let third = Night(start: start.addingTimeInterval(2 * 86400), end: start.addingTimeInterval(2 * 86400 + 3600))
      try await store.save(third, summary: third.summary(), scoreVersion: "1")
      await check(
        throwsNotFound(unknown) { try await store.delete(ids: [third.id, unknown]) },
        "delete(ids:) with an unknown night throws notFound")
      try await check(store.nightFiles().count == 2, "a failed delete(ids:) deletes none")
      try await store.delete(ids: [older.id, third.id])
      await check(first(store.observeSummaries()) == [], "delete(ids:) removes every night given")
      try await store.save(third, summary: third.summary(), scoreVersion: "1")
      try await store.deleteAll()
      await check(first(store.observeSummaries()) == [], "deleteAll empties the store")
    } catch {
      violations.append("SessionRepository: unexpected error \(error)")
    }
    return violations
  }

  // MARK: - RecordingCheckpointStore

  public static func checkpointStore(_ make: () async throws -> any RecordingCheckpointStore) async -> [String] {
    var violations: [String] = []
    func check(_ condition: Bool, _ message: String) {
      if !condition { violations.append("RecordingCheckpointStore: \(message)") }
    }
    do {
      let store = try await make()
      let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
      await check(store.load() == nil, "an empty store loads nothing")
      let first = Night(start: start, end: start.addingTimeInterval(60))
      var latest = first
      latest.end = start.addingTimeInterval(120)
      latest.events = [NightEvent(start: start.addingTimeInterval(10), duration: 5, intensity: .light)]
      await store.save(first)
      await check(store.load() == first, "a saved night loads back equal")
      await store.save(latest)
      await check(store.load() == latest, "a newer save replaces the older")
      await store.clear()
      await check(store.load() == nil, "clear removes it")
    } catch {
      violations.append("RecordingCheckpointStore: unexpected error \(error)")
    }
    return violations
  }

  // MARK: - ProfileStore, LifestyleLogStore, PreferencesStore

  public static func profileStore(_ make: () async throws -> any ProfileStore) async -> [String] {
    var violations: [String] = []
    func check(_ condition: Bool, _ message: String) {
      if !condition { violations.append("ProfileStore: \(message)") }
    }
    do {
      let store = try await make()
      await check(store.load() == SleepProfile(), "an empty store loads the empty profile")
      var profile = SleepProfile()
      profile.biologicalSex = .female
      try await store.save(profile)
      await check(store.load() == profile, "a saved profile loads back equal")
      await store.clear()
      await check(store.load() == SleepProfile(), "clear goes back to the empty profile")
    } catch {
      violations.append("ProfileStore: unexpected error \(error)")
    }
    return violations
  }

  public static func lifestyleLogStore(_ make: () async throws -> any LifestyleLogStore) async -> [String] {
    var violations: [String] = []
    func check(_ condition: Bool, _ message: String) {
      if !condition { violations.append("LifestyleLogStore: \(message)") }
    }
    do {
      let store = try await make()
      await check(store.logs().isEmpty, "an empty store has no logs")
      let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
      let first = LifestyleLog(night: start, chips: [])
      let second = LifestyleLog(night: start.addingTimeInterval(86400), chips: [])
      try await store.save(first)
      try await store.save(second)
      await check(store.logs() == [first, second], "logs come back in the order they were saved")
    } catch {
      violations.append("LifestyleLogStore: unexpected error \(error)")
    }
    return violations
  }

  public static func preferencesStore(_ make: () async throws -> any PreferencesStore) async -> [String] {
    var violations: [String] = []
    func check(_ condition: Bool, _ message: String) {
      if !condition { violations.append("PreferencesStore: \(message)") }
    }
    do {
      let store = try await make()
      await check(store.load() == AppPreferences(), "an empty store loads the defaults")
      var preferences = AppPreferences()
      preferences.sensitivity = .high
      preferences.hasCompletedOnboarding = true
      preferences.profilePromptDismissCount = 2
      await store.save(preferences)
      await check(store.load() == preferences, "saved preferences load back equal")
    } catch {
      violations.append("PreferencesStore: unexpected error \(error)")
    }
    return violations
  }

  // MARK: - MelodyStore

  /// `take` makes a new recorded file each call (the store moves it).
  @MainActor
  public static func melodyStore(_ make: () throws -> any MelodyStore, take: () throws -> URL) -> [String] {
    var violations: [String] = []
    func check(_ condition: Bool, _ message: String) {
      if !condition { violations.append("MelodyStore: \(message)") }
    }
    do {
      let store = try make()
      check(store.recordings().isEmpty, "an empty store has no recordings")
      guard let first = try store.save(take: take(), name: "One"),
            let second = try store.save(take: take(), name: "Two")
      else {
        violations.append("MelodyStore: save(take:name:) returned nil")
        return violations
      }
      check(first.id != second.id, "each recording gets its own id")
      check(store.recordings().map(\.id) == [first.id, second.id], "recordings are oldest first")
      check(store.recordings().map(\.customName) == ["One", "Two"], "recordings keep their names")
      check(store.url(for: first) != nil, "a recording has a file")
      store.delete(first)
      check(store.recordings().map(\.id) == [second.id], "delete removes the recording")
    } catch {
      violations.append("MelodyStore: unexpected error \(error)")
    }
    return violations
  }

  // MARK: - Helpers

  private static func first<Element: Sendable>(_ stream: AsyncStream<Element>) async -> Element? {
    for await element in stream {
      return element
    }
    return nil
  }

  private static func throwsNotFound(_ id: UUID, _ operation: () async throws -> Void) async -> Bool {
    do {
      try await operation()
      return false
    } catch {
      return (error as? SessionError) == .notFound(id)
    }
  }
}
