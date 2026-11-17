import Foundation
import SleepCore
import SleepDomain

/// Preferences in memory.
public actor FakePreferencesStore: PreferencesStore {
  public private(set) var preferences: AppPreferences

  public init(_ preferences: AppPreferences = AppPreferences()) {
    self.preferences = preferences
  }

  public func load() async -> AppPreferences {
    preferences
  }

  public func save(_ preferences: AppPreferences) async {
    self.preferences = preferences
  }
}

/// The profile in memory; counts saves.
public actor FakeProfileStore: ProfileStore {
  public private(set) var profile: SleepProfile
  public private(set) var saves = 0
  public private(set) var clears = 0

  public init(_ profile: SleepProfile = SleepProfile()) {
    self.profile = profile
  }

  public func load() async -> SleepProfile {
    profile
  }

  public func save(_ profile: SleepProfile) async throws {
    self.profile = profile
    saves += 1
  }

  public func clear() async {
    profile = SleepProfile()
    clears += 1
  }
}

/// Apple Health that answers `granted` and records the nights written.
public actor FakeHealthAccess: HealthAccess {
  public private(set) var saved: [Night.ID] = []
  public private(set) var requests = 0
  private let granted: Bool
  private let stages: [SleepStageSegment]

  public init(granted: Bool = true, stages: [SleepStageSegment] = []) {
    self.granted = granted
    self.stages = stages
  }

  public func stages(from _: Date, to _: Date) async throws -> [SleepStageSegment] {
    stages
  }

  public func requestAuthorization() async -> Bool {
    requests += 1
    return granted
  }

  public func save(_ night: Night, summary _: NightSummary) async {
    saved.append(night.id)
  }
}

/// A raw log in memory.
public actor FakeRawLogWriter: RawLogWriter {
  public private(set) var night: UUID?
  public private(set) var metadata: RawLogMetadata?
  public private(set) var samples: [SnoreSample] = []
  public private(set) var finished = false

  public init() {}

  public func begin(night id: UUID, metadata: RawLogMetadata) async {
    night = id
    self.metadata = metadata
  }

  public func append(_ samples: [SnoreSample]) async {
    self.samples += samples
  }

  public func finish() async {
    finished = true
  }
}
