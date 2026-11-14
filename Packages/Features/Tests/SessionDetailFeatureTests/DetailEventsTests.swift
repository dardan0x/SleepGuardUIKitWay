import Foundation
import SleepCore
import Testing
@testable import SessionDetailFeature

struct DetailEventsTests {
  private let start = Date(timeIntervalSinceReferenceDate: 0)

  private func event(at seconds: TimeInterval, duration: TimeInterval = 60, category: SoundCategory = .snoring, intensity: SnoreIntensity = .light) -> NightEvent {
    NightEvent(start: start.addingTimeInterval(seconds), duration: duration, category: category, intensity: intensity)
  }

  @Test func snoringIsOneRowPerEpisodeKeyedByItsLongestEvent() throws {
    let short = event(at: 0, duration: 30, intensity: .light)
    let long = event(at: 100, duration: 120, intensity: .epic) // same episode
    let night = Night(start: start, end: start.addingTimeInterval(8 * 3600), events: [short, long])

    let rows = DetailEventRow.make(episodes: night.displayableEpisodes, events: night.events, filter: .all)

    #expect(rows.count == 1)
    let row = try #require(rows.first)
    #expect(row.id == long.id)
    #expect(row.start == short.start)
    #expect(row.duration == 150)
    #expect(row.intensity == .epic)
  }

  @Test func otherEventsAreSeparateRowsInTimeOrder() {
    let talking = event(at: 3600, duration: 12, category: .sleepTalking)
    let cough = event(at: 600, duration: 4, category: .coughing)
    let snore = event(at: 7200, duration: 60)
    let night = Night(start: start, end: start.addingTimeInterval(8 * 3600), events: [talking, cough, snore])

    let rows = DetailEventRow.make(episodes: night.displayableEpisodes, events: night.events, filter: .all)
    #expect(rows.map(\.id) == [cough.id, talking.id, snore.id])
    #expect(DetailEventRow.make(episodes: night.displayableEpisodes, events: night.events, filter: .noise).map(\.id) == [cough.id])
    #expect(DetailEventRow.make(episodes: night.displayableEpisodes, events: night.events, filter: .snoring).map(\.id) == [snore.id])
  }

  @Test func hiddenMicroEpisodesHaveNoRow() {
    let night = Night(start: start, end: start.addingTimeInterval(8 * 3600), events: [event(at: 0, duration: 2)])
    #expect(DetailEventRow.make(episodes: night.displayableEpisodes, events: night.events, filter: .all).isEmpty)
  }

  @Test func filtersAreOfferedOnlyForMoreThanOneKind() {
    #expect(EventFilter.available(for: [event(at: 0), event(at: 600)]).isEmpty)
    #expect(EventFilter.available(for: [event(at: 0), event(at: 600, category: .other)]) == [.all, .snoring, .noise])
    #expect(EventFilter.available(for: [event(at: 0), event(at: 10, category: .sleepTalking), event(at: 20, category: .noise)]) == [.all, .snoring, .sleepTalking, .noise])
  }
}
