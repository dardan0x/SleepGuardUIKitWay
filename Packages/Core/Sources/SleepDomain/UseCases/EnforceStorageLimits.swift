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
    let allFiles = await files.allFileNames()
    var sizes: [String: Int64] = [:]
    for name in Set(allFiles) {
      sizes[name] = await files.size(ofFileNamed: name)
    }
    // SleepCore's StorageSweep decides, as in SleepGuard: which nights lose
    // their audio, and which files no night (or the night in progress) names.
    let sweep = await StorageSweep.make(
      nights: nights, sizes: sizes, allFiles: allFiles, inProgress: checkpoints.load(), now: now(),
      maxDays: settings.maxDaysLimit, maxMB: settings.maxMegabytesLimit)

    var report = Report()
    let byID = Dictionary(nights.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    for id in sweep.plan.all {
      guard let night = byID[id] else { continue }
      let removed = try await removeAudio(of: night)
      report.filesRemoved += removed.files
      report.bytesRemoved += removed.bytes
      if removed.files > 0 {
        if sweep.plan.dayLimited.contains(id) { report.dayLimitNights += 1 } else { report.sizeLimitNights += 1 }
      }
    }

    for name in sweep.leftovers {
      report.bytesRemoved += sizes[name] ?? 0
    }
    await files.removeFiles(named: sweep.leftovers)
    report.leftoverFiles = sweep.leftovers.count
    report.filesRemoved += sweep.leftovers.count
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
}
