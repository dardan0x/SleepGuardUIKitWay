import Foundation
import SleepCore

/// Keeps the audio within the limits chosen in Settings, and removes files no
/// night refers to.
///
/// A use case because it applies a rule and coordinates three ports. Which
/// nights lose their audio is SleepCore's `StoragePlan` (the same choice as
/// SleepGuard's): older than the day limit, then the oldest over the size
/// limit. A night keeps its record and events; only its clips and raw
/// recording go, the reference first, then the files.
///
/// Leftovers are files in the clips folder that neither a saved night nor the
/// checkpointed night refers to: a clip a crash left half written, a raw clip
/// whose compression finished but wasn't saved. Run it when no night is being
/// recorded (at launch, after a save, after lowering a limit): the night in
/// progress has files no record names yet.
public struct EnforceStorageLimits: Sendable {
  public struct Report: Equatable, Sendable {
    public var filesRemoved = 0
    public var bytesRemoved: Int64 = 0
    /// Nights that lost audio to the day limit, and to the size limit.
    public var dayLimitNights = 0
    public var sizeLimitNights = 0
    /// Files no night refers to, removed.
    public var leftoverFiles = 0

    public init() {}

    public var nightsAffected: Int { dayLimitNights + sizeLimitNights }
  }

  private let sessions: any SessionRepository
  private let files: any SessionFileStore
  private let checkpoints: any RecordingCheckpointStore
  private let preferences: any PreferencesStore
  private let now: @Sendable () -> Date

  public init(
    sessions: any SessionRepository,
    files: any SessionFileStore,
    checkpoints: any RecordingCheckpointStore,
    preferences: any PreferencesStore,
    now: @escaping @Sendable () -> Date = { Date() })
  {
    self.sessions = sessions
    self.files = files
    self.checkpoints = checkpoints
    self.preferences = preferences
    self.now = now
  }

  @discardableResult
  public func callAsFunction() async throws -> Report {
    let settings = await preferences.load()
    let nights = try await sessions.nightFiles()
    var sizes: [Night.ID: Int64] = [:]
    for night in nights {
      var bytes: Int64 = 0
      for name in night.allFileNames {
        bytes += await files.size(ofFileNamed: name)
      }
      sizes[night.id] = bytes
    }
    let plan = StoragePlan.make(
      nights: nights.map { StoragePlan.Night(id: $0.id, start: $0.start, bytes: sizes[$0.id] ?? 0) },
      now: now(), maxDays: settings.maxDaysLimit, maxMB: settings.maxMegabytesLimit)

    var report = Report()
    let byID = Dictionary(nights.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    for id in plan.all {
      guard let night = byID[id] else { continue }
      let removed = try await removeAudio(of: night)
      report.filesRemoved += removed.files
      report.bytesRemoved += removed.bytes
      if removed.files > 0 {
        if plan.dayLimited.contains(id) { report.dayLimitNights += 1 } else { report.sizeLimitNights += 1 }
      }
    }

    let leftovers = await leftoverFiles(nights: nights)
    for name in leftovers {
      report.bytesRemoved += await files.size(ofFileNamed: name)
    }
    await files.removeFiles(named: leftovers)
    report.leftoverFiles = leftovers.count
    report.filesRemoved += leftovers.count
    return report
  }

  /// The night forgets its clips first, then the files go: if removing fails,
  /// what's left is files no night refers to (the next run takes them).
  private func removeAudio(of night: NightFiles) async throws -> (files: Int, bytes: Int64) {
    var existing: [String] = []
    var bytes: Int64 = 0
    for name in night.allFileNames {
      let size = await files.size(ofFileNamed: name)
      if size > 0 {
        existing.append(name)
        bytes += size
      }
    }
    if !night.clipFileNames.isEmpty {
      try await sessions.removeClips(of: night.id)
    }
    await files.removeFiles(named: existing)
    return (existing.count, bytes)
  }

  private func leftoverFiles(nights: [NightFiles]) async -> [String] {
    var referenced = Set(nights.flatMap(\.allFileNames))
    if let inProgress = await checkpoints.load() {
      referenced.formUnion(inProgress.events.compactMap(\.clipFileName))
      referenced.formUnion(RawRecording.fileNames(for: inProgress.id))
    }
    return await files.allFileNames().filter { !referenced.contains($0) }
  }
}
