import Foundation
import SleepCore

/// Which events the list shows.
enum EventFilter: CaseIterable, Hashable {
  case all
  case snoring
  case sleepTalking
  case noise

  func includes(_ category: SoundCategory) -> Bool {
    switch self {
    case .all: true
    case .snoring: category == .snoring
    case .sleepTalking: category == .sleepTalking
    case .noise: category == .noise || category == .coughing || category == .other
    }
  }

  /// The filters worth offering: `.all` plus every kind present, only when
  /// there is more than one kind (otherwise the picker would do nothing).
  static func available(for events: [NightEvent]) -> [EventFilter] {
    let present = allCases.dropFirst().filter { filter in events.contains { filter.includes($0.category) } }
    return present.count > 1 ? [.all] + present : []
  }
}

/// One row in the event list. Public so "Show all" can hand the rows on
/// screen to the events sheet; only this module creates them.
public struct DetailEventRow: Identifiable, Equatable, Sendable {
  /// The event that plays when the row is tapped (an episode's representative).
  public let id: UUID
  public let start: Date
  /// For snoring, the whole episode's summed event time.
  public let duration: TimeInterval
  public let category: SoundCategory
  public let intensity: SnoreIntensity

  /// Snoring is shown per displayable episode (keyed by its representative
  /// event), every other event on its own. Time order. Same rule as SleepGuard.
  static func make(episodes: [NightEpisode], events: [NightEvent], filter: EventFilter) -> [DetailEventRow] {
    let snoring = episodes.map { episode in
      DetailEventRow(
        id: episode.representativeEvent.id, start: episode.start, duration: episode.snoreDuration,
        category: .snoring, intensity: episode.intensity)
    }
    let others = events.filter { $0.category != .snoring }.map { event in
      DetailEventRow(id: event.id, start: event.start, duration: event.duration, category: event.category, intensity: event.intensity)
    }
    return (snoring + others).filter { filter.includes($0.category) }.sorted { $0.start < $1.start }
  }
}
