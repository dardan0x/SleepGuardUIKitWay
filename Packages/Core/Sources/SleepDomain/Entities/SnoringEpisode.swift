import Foundation
import SleepCore

/// Snoring events close enough in time to read as one episode. Built by
/// `SnoringEpisodes` from a session's snoring events; never stored.
public struct SnoringEpisode: Sendable, Equatable, Identifiable {
  /// The first event's id, so an episode keeps its identity between builds.
  public var id: UUID {
    events[0].id
  }

  /// Time-ordered; never empty.
  public let events: [SnoreEvent]

  public init(events: [SnoreEvent]) {
    precondition(!events.isEmpty, "An episode has at least one event")
    self.events = events.sorted { $0.start < $1.start }
  }

  public var start: Date {
    events[0].start
  }

  /// From the first event's start to the latest event end.
  public var end: Date {
    events.map(\.end).max() ?? start
  }

  public var duration: TimeInterval {
    end.timeIntervalSince(start)
  }

  /// The loudest intensity of any event in the episode.
  public var intensity: SnoreIntensity {
    events.map(\.intensity).max { $0.rank < $1.rank } ?? .quiet
  }

  /// Sum of the events' spans.
  public var snoreDuration: TimeInterval {
    events.reduce(0) { $0 + $1.duration }
  }

  /// Sum of measured sound (bursts), melody gaps excluded.
  public var measuredDuration: TimeInterval {
    events.reduce(0) { $0 + $1.measuredDuration }
  }

  /// The loudest moment in the episode.
  public var peakDB: Double {
    events.map(\.peakDB).max() ?? 0
  }

  /// Duration-weighted mean of the events' average level.
  public var averageDB: Double {
    let total = snoreDuration
    guard total > 0 else { return 0 }
    return events.reduce(0) { $0 + $1.averageDB * $1.duration } / total
  }

  /// The longest event: the one a list row plays first.
  public var representativeEvent: SnoreEvent {
    events.max { $0.duration < $1.duration } ?? events[0]
  }
}
