import Foundation
import SleepCore

/// One calendar day in the list: every night that started that day.
struct HistoryDay: Identifiable, Equatable {
  /// Start of the day.
  let id: Date
  /// Newest first. Never empty.
  let nights: [NightSummary]

  var date: Date {
    id
  }

  var averageScore: Int {
    nights.map(\.score).reduce(0, +) / nights.count
  }

  var totalDuration: TimeInterval {
    nights.map(\.duration).reduce(0, +)
  }

  var totalEvents: Int {
    nights.map(\.eventCount).reduce(0, +)
  }
}

/// One calendar month in the list.
struct HistoryMonth: Identifiable, Equatable {
  /// Start of the month.
  let id: Date
  /// Newest first. Never empty.
  let days: [HistoryDay]

  var month: Date {
    id
  }
}

/// Groups nights by month, then by the day they started. Newest first at every
/// level. Same grouping as SleepGuard's list.
enum HistorySections {
  static func make(from summaries: [NightSummary], calendar: Calendar) -> [HistoryMonth] {
    let byDay = Dictionary(grouping: summaries) { calendar.startOfDay(for: $0.start) }
    let days = byDay
      .map { day, nights in HistoryDay(id: day, nights: nights.sorted { $0.start > $1.start }) }
      .sorted { $0.date > $1.date }

    let byMonth = Dictionary(grouping: days) { day in
      calendar.dateInterval(of: .month, for: day.date)?.start ?? day.date
    }
    return byMonth
      .map { month, days in HistoryMonth(id: month, days: days.sorted { $0.date > $1.date }) }
      .sorted { $0.month > $1.month }
  }
}
