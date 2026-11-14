import Foundation
import SleepCore
import Testing
@testable import SleepDomain

struct EntityTests {
  private let start = Date(timeIntervalSinceReferenceDate: 0)

  @Test func sessionDurationIsEndMinusStartGapsIncluded() {
    let session = SleepSession(
      start: start,
      end: start.addingTimeInterval(8 * 3600),
      recordingGaps: [RecordingGap(startOffset: 600, duration: 120)])
    #expect(session.duration == 8 * 3600)
  }

  @Test func sessionsCompareByValue() {
    let id = UUID()
    let a = SleepSession(id: id, start: start, end: start.addingTimeInterval(60))
    var b = a
    #expect(a == b)
    b.sleepStages = [SleepStageSegment(stage: .deep, startOffset: 0, duration: 60)]
    #expect(a != b)
  }

  /// Bursts at 0–4 s and 6–9 s inside a 9 s event: 7 s measured.
  @Test func measuredDurationIsTheBurstSum() {
    let event = SnoreEvent(
      start: start, duration: 9, intensity: .loud,
      bursts: [SnoreBurst(startOffset: 0, endOffset: 4), SnoreBurst(startOffset: 6, endOffset: 9)])
    #expect(event.measuredDuration == 7)
    #expect(event.end == start.addingTimeInterval(9))
  }

  @Test func measuredDurationFallsBackToTheSpanWithoutBursts() {
    let event = SnoreEvent(start: start, duration: 5, category: .sleepTalking, intensity: .quiet)
    #expect(event.measuredDuration == 5)
  }

  /// Events at 0 s (10 s, light) and 100 s (30 s, loud), given out of order.
  @Test func episodeSortsItsEventsAndSpansThem() {
    let late = SnoreEvent(start: start.addingTimeInterval(100), duration: 30, intensity: .loud)
    let early = SnoreEvent(start: start, duration: 10, intensity: .light)
    let episode = SnoringEpisode(events: [late, early])

    #expect(episode.events.map(\.id) == [early.id, late.id])
    #expect(episode.id == early.id)
    #expect(episode.duration == 130)
    #expect(episode.snoreDuration == 40)
    #expect(episode.intensity == .loud)
    #expect(episode.representativeEvent.id == late.id)
  }

  /// A long event that ends after a later, shorter one sets the episode's end.
  @Test func episodeEndIsTheLatestEventEnd() {
    let long = SnoreEvent(start: start, duration: 300, intensity: .quiet)
    let inside = SnoreEvent(start: start.addingTimeInterval(60), duration: 10, intensity: .quiet)
    #expect(SnoringEpisode(events: [long, inside]).duration == 300)
  }
}
