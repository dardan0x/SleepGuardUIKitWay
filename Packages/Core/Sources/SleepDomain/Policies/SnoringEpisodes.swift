import Foundation
import SleepCore

/// Groups snoring events into episodes. Same rules as SleepGuard, so the two
/// apps show and score the same night the same way.
public enum SnoringEpisodes {
  /// Events whose gap (previous episode end → next start) is at most this merge.
  public static let mergeGap: TimeInterval = 300
  /// Episodes shorter than this (summed event spans) are hidden and not
  /// counted as events: likely false positives. Their time still counts as snoring.
  public static let minimumDisplayDuration: TimeInterval = 3

  /// Every episode, in time order. Non-snoring events are ignored.
  public static func all(in events: [SnoreEvent]) -> [SnoringEpisode] {
    let snoring = events.filter { $0.category == .snoring }.sorted { $0.start < $1.start }
    guard let first = snoring.first else { return [] }

    var episodes: [SnoringEpisode] = []
    var current = [first]
    var currentEnd = first.end
    for event in snoring.dropFirst() {
      if event.start.timeIntervalSince(currentEnd) <= mergeGap {
        current.append(event)
        currentEnd = max(currentEnd, event.end)
      } else {
        episodes.append(SnoringEpisode(events: current))
        current = [event]
        currentEnd = event.end
      }
    }
    episodes.append(SnoringEpisode(events: current))
    return episodes
  }

  /// The episodes worth showing.
  public static func displayable(in events: [SnoreEvent]) -> [SnoringEpisode] {
    all(in: events).filter { $0.snoreDuration >= minimumDisplayDuration }
  }

  /// What to play when a list row for `event` is tapped. A snoring row stands
  /// for a whole episode and is keyed by its representative event, so that
  /// event plays the episode's events in order; anything else plays alone.
  public static func playbackEvents(for event: SnoreEvent, in events: [SnoreEvent]) -> [SnoreEvent] {
    displayable(in: events).first { $0.representativeEvent.id == event.id }?.events ?? [event]
  }
}
