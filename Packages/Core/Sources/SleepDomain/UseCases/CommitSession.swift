import Foundation
import SleepCore

/// Saves a night just recorded, with the summary lists show.
///
/// A use case because it applies the night rules: the summary (score,
/// snoring time, events) is computed once here, from SleepCore, and stored
/// with the night, as SleepGuard's `SessionCommitter` caches its score.
/// A night under `Night.minimumSaveDuration` is refused.
public struct CommitSession: Sendable {
  public enum Failure: Error, Equatable {
    case tooShort
  }

  private let sessions: any SessionRepository
  private let scoreConfig: SleepScoreConfig

  public init(sessions: any SessionRepository, scoreConfig: SleepScoreConfig = .default) {
    self.sessions = sessions
    self.scoreConfig = scoreConfig
  }

  public func callAsFunction(_ night: Night) async throws {
    guard night.duration >= Night.minimumSaveDuration else { throw Failure.tooShort }
    try await sessions.save(night, summary: night.summary(using: scoreConfig))
  }
}
