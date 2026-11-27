import Foundation
import SleepCore

/// Everything the session detail screen shows.
public struct SessionDetail: Sendable, Equatable {
  public let session: Night
  public let summary: NightSummary
  /// Displayable snoring episodes, in time order.
  public let episodes: [NightEpisode]

  public init(session: Night, summary: NightSummary, episodes: [NightEpisode]) {
    self.session = session
    self.summary = summary
    self.episodes = episodes
  }

  init(_ session: Night, scoreConfig: SleepScoreConfig) {
    self.init(session: session, summary: session.summary(using: scoreConfig), episodes: session.displayableEpisodes)
  }
}

/// Opens a night for the detail screen. A query: it never writes. Sleep
/// stages are added afterwards by `EnrichNightWithStagesUseCase`.
public struct LoadSessionDetailUseCase: Sendable {
  private let sessions: any SessionRepositoryPort
  private let scoreConfig: SleepScoreConfig

  public init(sessions: any SessionRepositoryPort, scoreConfig: SleepScoreConfig = .default) {
    self.sessions = sessions
    self.scoreConfig = scoreConfig
  }

  public func callAsFunction(_ id: Night.ID) async throws -> SessionDetail {
    try await SessionDetail(sessions.session(id: id), scoreConfig: scoreConfig)
  }
}

/// Adds sleep stages to a night that has none, when the stage source has
/// some, and stores them with the new score (stages change it). A command,
/// apart from the load, so opening a night never depends on a write.
///
/// Stages are optional extra data. If the source fails or has none, the night
/// is unchanged. If storing them fails, the stages are still returned for the
/// screen and the store keeps the night without them, so the next open tries
/// again.
public struct EnrichNightWithStagesUseCase: Sendable {
  private let sessions: any SessionRepositoryPort
  private let sleepStages: any SleepStageSourcePort
  private let scoreConfig: SleepScoreConfig

  public init(sessions: any SessionRepositoryPort, sleepStages: any SleepStageSourcePort, scoreConfig: SleepScoreConfig = .default) {
    self.sessions = sessions
    self.sleepStages = sleepStages
    self.scoreConfig = scoreConfig
  }

  /// The night with its stages, or `nil` when there was nothing to add.
  public func callAsFunction(_ night: Night) async -> SessionDetail? {
    guard night.sleepStages.isEmpty,
          let stages = try? await sleepStages.stages(from: night.start, to: night.end),
          !stages.isEmpty else { return nil }
    var night = night
    night.sleepStages = stages
    let detail = SessionDetail(night, scoreConfig: scoreConfig)
    try? await sessions.updateStages(
      of: night.id, stages: stages, summary: detail.summary, scoreVersion: SleepScore.cacheVersion(for: scoreConfig))
    return detail
  }
}
