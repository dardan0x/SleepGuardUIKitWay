import SleepCore
import SleepGuardContentKit
import SwiftUI

/// What a night's detail shows, in order, as diffable sections and items:
/// the same pieces and conditions as the shared `NightDetailContent`, laid
/// out by a UIKit collection view instead of a stack.
struct NightDetailItems: Equatable {
  nonisolated enum Section: Hashable, Sendable {
    case header, chart, banners, filter, events
  }

  nonisolated enum Item: Hashable, Sendable {
    case header
    case stages
    case timeline
    case gapsBanner
    case batteryBanner
    case filter
    case eventsTitle
    case event(EventListRow.ID)
    case showAll
  }

  struct Group: Equatable {
    let section: Section
    let items: [Item]
  }

  let groups: [Group]
  /// Every row under the filter; `.event` items are the first few of them.
  let rows: [EventListRow]
  let stages: SleepStageBreakdown?

  /// Rows before "Show all", the shared content's number.
  static let visibleRows = NightDetailContent<EmptyView, EmptyView>.visibleRows

  init(night: Night, filter: EventFilter) {
    rows = EventListRow.rows(for: night, filter: filter)
    stages = SleepStageBreakdown(segments: night.sleepStages)
    var banners: [Item] = []
    if !night.recordingGaps.isEmpty { banners.append(.gapsBanner) }
    if night.endReason == .lowBattery { banners.append(.batteryBanner) }
    var events: [Item] = [.eventsTitle]
    events += rows.prefix(Self.visibleRows).map { .event($0.id) }
    if rows.count > Self.visibleRows { events.append(.showAll) }
    groups = [
      Group(section: .header, items: [.header]),
      Group(section: .chart, items: (stages == nil ? [] : [.stages]) + [.timeline]),
      Group(section: .banners, items: banners),
      Group(section: .filter, items: EventFilter.options(for: night.events).isEmpty ? [] : [.filter]),
      Group(section: .events, items: events),
    ].filter { !$0.items.isEmpty }
  }

  func row(_ id: EventListRow.ID) -> EventListRow? {
    rows.first { $0.id == id }
  }
}
