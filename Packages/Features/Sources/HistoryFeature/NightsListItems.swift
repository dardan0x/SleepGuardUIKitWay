import SleepCore

/// What the nights list shows, as diffable identifiers: a section per month,
/// an item per day, newest first (SleepCore's `NightMonth`). The list looks
/// each day up by its identifier when it draws a cell.
struct NightsListItems: Equatable {
  struct Section: Equatable {
    let month: NightMonth.ID
    let days: [NightDay.ID]
  }

  let sections: [Section]
  private let days: [NightDay.ID: NightDay]

  init(months: [NightMonth]) {
    sections = months.map { Section(month: $0.id, days: $0.days.map(\.id)) }
    days = Dictionary(months.flatMap(\.days).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
  }

  func day(_ id: NightDay.ID) -> NightDay? {
    days[id]
  }

  /// Days that are still listed, so a stale expansion is dropped.
  func listed(_ ids: Set<NightDay.ID>) -> Set<NightDay.ID> {
    ids.filter { days[$0] != nil }
  }
}
