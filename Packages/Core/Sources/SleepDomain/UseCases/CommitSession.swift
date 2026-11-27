import Foundation
import SleepCore

/// Saves a night just recorded (or recovered), with the summary lists show,
/// then clears its checkpoint.
///
/// A use case because it applies the night rules and coordinates two ports:
/// the summary (score, snoring time, events) is computed once here, from
/// SleepCore, and stored with the night, as SleepGuard's `SessionCommitter`
/// caches its score. A night shorter than the `SaveRules` minimum is refused.
/// The checkpoint is cleared only after the save succeeds. Then, if the
/// person turned it on and the brand has Apple Health, the night is written
/// there too (a failure there doesn't undo the save).
public struct CommitSession: Sendable {
  public enum Failure: Error, Equatable {
    case tooShort
  }

  private let sessions: any SessionRepository
  private let checkpoints: any RecordingCheckpointStore
  private let scoreConfig: SleepScoreConfig
  private let saveRules: SaveRules
  private let health: (any HealthAccess)?
  private let preferences: (any PreferencesStore)?

  public init(
    sessions: any SessionRepository,
    checkpoints: any RecordingCheckpointStore,
    health: (any HealthAccess)? = nil,
    preferences: (any PreferencesStore)? = nil,
    scoreConfig: SleepScoreConfig = .default,
    saveRules: SaveRules = .standard)
  {
    self.sessions = sessions
    self.checkpoints = checkpoints
    self.health = health
    self.preferences = preferences
    self.scoreConfig = scoreConfig
    self.saveRules = saveRules
  }

  public func callAsFunction(_ night: Night) async throws {
    guard saveRules.isLongEnough(night.duration) else { throw Failure.tooShort }
    let summary = night.summary(using: scoreConfig)
    try await sessions.save(night, summary: summary, scoreVersion: SleepScore.cacheVersion(for: scoreConfig))
    await checkpoints.clear()
    if let health, await preferences?.load().syncToHealth == true {
      await health.save(night, summary: summary)
    }
  }
}
