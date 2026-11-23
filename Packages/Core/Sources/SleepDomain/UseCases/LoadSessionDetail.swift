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
}

/// Opens a night for the detail screen.
///
/// If the night has no sleep stages yet and the stage source has some, they
/// are added and the night is saved again with its new score (stages change
/// the score). A use case because it coordinates two ports and applies the
/// score policy.
public struct LoadSessionDetail: Sendable {
  private let sessions: any SessionRepository
  private let sleepStages: any SleepStageSource
  private let scoreConfig: SleepScoreConfig

  public init(sessions: any SessionRepository, sleepStages: any SleepStageSource, scoreConfig: SleepScoreConfig = .default) {
    self.sessions = sessions
    self.sleepStages = sleepStages
    self.scoreConfig = scoreConfig
  }

  public func callAsFunction(_ id: Night.ID) async throws -> SessionDetail {
    var session = try await sessions.session(id: id)

    // Stages are optional extra data: if the source fails, the night still
    // opens without them, and the next open tries again.
    if session.sleepStages.isEmpty,
       let stages = try? await sleepStages.stages(from: session.start, to: session.end),
       !stages.isEmpty
    {
      session.sleepStages = stages
      try await sessions.save(session, summary: session.summary(using: scoreConfig))
    }

    return SessionDetail(
      session: session,
      summary: session.summary(using: scoreConfig),
      episodes: session.displayableEpisodes)
  }
}
