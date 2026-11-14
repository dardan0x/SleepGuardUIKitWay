import Foundation

/// What a list row or a chart needs about a night, without its events.
///
/// Stored alongside the session when it is saved, so lists never load events.
/// (SleepGuard reaches the same goal with cached fields on its database model.)
public struct SessionSummary: Sendable, Equatable, Identifiable {
  public let id: UUID
  public var start: Date
  public var end: Date
  /// 0…100.
  public var score: Int
  /// Time counted as snoring, the score's input (see `SnoringDuration`).
  public var snoringDuration: TimeInterval
  /// Snoring episodes long enough to show, plus other events.
  public var eventCount: Int

  public init(id: UUID, start: Date, end: Date, score: Int, snoringDuration: TimeInterval, eventCount: Int) {
    self.id = id
    self.start = start
    self.end = end
    self.score = score
    self.snoringDuration = snoringDuration
    self.eventCount = eventCount
  }

  public var duration: TimeInterval {
    end.timeIntervalSince(start)
  }
}
