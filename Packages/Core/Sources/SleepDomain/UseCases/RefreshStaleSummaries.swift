import Foundation
import SleepCore

/// Recomputes the stored summaries made by another score formula or config,
/// so History, Statistics and the briefing never mix two formulas (SleepGuard's
/// `refreshStaleCachedScores` does the same at launch).
///
/// Nights are read one at a time and written in batches: each batch is one
/// store write and one list update. A night that fails to load is skipped and
/// stays stale, so the next launch tries it again. Stops when cancelled.
public struct RefreshStaleSummaries: Sendable {
  public static let batchSize = 20

  private let sessions: any SessionRepository
  private let scoreConfig: SleepScoreConfig

  public init(sessions: any SessionRepository, scoreConfig: SleepScoreConfig = .default) {
    self.sessions = sessions
    self.scoreConfig = scoreConfig
  }

  /// How many summaries were refreshed.
  @discardableResult
  public func callAsFunction() async throws -> Int {
    let version = SleepScore.cacheVersion(for: scoreConfig)
    let stale = try await sessions.staleNightIDs(currentVersion: version)
    var refreshed = 0
    var start = stale.startIndex
    while start < stale.endIndex, !Task.isCancelled {
      let end = min(start + Self.batchSize, stale.endIndex)
      var batch: [NightSummary] = []
      for id in stale[start..<end] {
        guard let night = try? await sessions.session(id: id) else { continue }
        batch.append(night.summary(using: scoreConfig))
      }
      if !batch.isEmpty {
        try await sessions.updateSummaries(batch, scoreVersion: version)
        refreshed += batch.count
      }
      start = end
    }
    return refreshed
  }
}
