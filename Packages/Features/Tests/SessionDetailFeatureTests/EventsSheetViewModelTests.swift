import Foundation
import SleepCore
import Testing
@testable import SessionDetailFeature

/// Play on a card plays that row's episode, starting with the row's event;
/// the stages sheet's close routes out.
@MainActor
struct EventsSheetViewModelTests {
  private let start = Date(timeIntervalSinceReferenceDate: 815_000_000)

  @Test func playingARowPlaysItsEpisode() throws {
    let events = (0..<3).map {
      NightEvent(start: start.addingTimeInterval(Double($0) * 20), duration: 10, category: .snoring, intensity: .loud)
    }
    let night = Night(start: start, end: start.addingTimeInterval(3600), events: events)
    let rows = EventListRow.rows(for: night)
    var played: [([NightEvent], NightEvent.ID)] = []
    let viewModel = EventsSheetViewModel(
      rows: rows, events: events, routes: EventsSheetRoutes(playEvents: { played.append(($0, $1)) }))
    let row = try #require(rows.first)

    viewModel.play(row)

    #expect(played.map(\.0) == [row.playback(in: events)])
    #expect(played.map(\.1) == [row.id])
  }

  @Test func closingTheStagesSheetRoutesOut() throws {
    var closed = 0
    let stages = try #require(SleepStageBreakdown(segments: [SleepStageSegment(stage: .deep, startOffset: 0, duration: 600)]))
    SleepStagesInfoViewModel(breakdown: stages, routes: SleepStagesInfoRoutes(close: { closed += 1 })).close()
    #expect(closed == 1)
  }
}
