import Foundation
import SleepCore
import Testing
@testable import SessionDetailFeature

/// The detail's sections, in the shared content's order and on its
/// conditions: stages only with stages, banners only when they apply, the
/// filter only with something to filter, "Show all" past the visible rows.
@MainActor
struct NightDetailItemsTests {
  private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  private func night(events: Int, stages: Bool = false) -> Night {
    let list = (0..<events).map {
      NightEvent(start: start.addingTimeInterval(Double($0) * 900), duration: 30,
                 category: $0.isMultiple(of: 2) ? .sleepTalking : .noise, intensity: .quiet)
    }
    return Night(
      start: start, end: start.addingTimeInterval(8 * 3600), events: list,
      sleepStages: stages ? [SleepStageSegment(stage: .deep, startOffset: 0, duration: 3600)] : [])
  }

  @Test func aQuietNightHasTheHeaderTimelineAndAnEmptyList() {
    let items = NightDetailItems(night: night(events: 0), filter: .all)
    #expect(items.groups.map(\.section) == [.header, .chart, .events])
    #expect(items.groups[1].items == [.timeline])
    #expect(items.groups.last?.items == [.eventsTitle])
  }

  @Test func stagesComeBeforeTheTimeline() {
    let items = NightDetailItems(night: night(events: 0, stages: true), filter: .all)
    #expect(items.groups[1].items == [.stages, .timeline])
  }

  @Test func showAllComesPastTheVisibleRows() {
    let items = NightDetailItems(night: night(events: NightDetailItems.visibleRows + 2), filter: .all)
    #expect(items.groups.map(\.section).contains(.filter))
    let events = items.groups.last?.items ?? []
    #expect(events.first == .eventsTitle)
    #expect(events.last == .showAll)
    #expect(events.count == NightDetailItems.visibleRows + 2)
    #expect(items.rows.count == NightDetailItems.visibleRows + 2)
  }

  @Test func theFilterNarrowsTheRows() {
    let items = NightDetailItems(night: night(events: 3), filter: .snoring)
    #expect(items.rows.isEmpty)
  }
}
