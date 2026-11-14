import Foundation
import SleepCore
import Testing
@testable import SleepDomain

/// Ported from SleepGuard's `SnoringEpisodeTests`: same inputs, same expectations.
struct SnoringEpisodesTests {
  @Test func noSnoringEventsMeansNoEpisodes() {
    #expect(SnoringEpisodes.all(in: []).isEmpty)
    #expect(SnoringEpisodes.all(in: [Night.event(at: 0, category: .sleepTalking)]).isEmpty)
  }

  @Test func eventsExactlyFiveMinutesApartMerge() {
    // e1 ends at 60 s; e2 starts at 360 s → gap 300 s (≤ 300 merges)
    let e1 = Night.event(at: 0, duration: 60, intensity: .light)
    let e2 = Night.event(at: 360, duration: 60, intensity: .epic)
    let episodes = SnoringEpisodes.all(in: [e1, e2])
    #expect(episodes.count == 1)
    #expect(episodes[0].duration == 420)
    #expect(episodes[0].intensity == .epic)
    #expect(episodes[0].id == e1.id)
  }

  @Test func eventsMoreThanFiveMinutesApartSplit() {
    let e1 = Night.event(at: 0, duration: 60)
    let e2 = Night.event(at: 361, duration: 60)
    let episodes = SnoringEpisodes.all(in: [e1, e2])
    #expect(episodes.map(\.id) == [e1.id, e2.id])
    #expect(episodes.map(\.duration) == [60, 60])
  }

  @Test func eventsAreOrderedByTimeBeforeGrouping() {
    let episodes = SnoringEpisodes.all(in: [Night.event(at: 3600), Night.event(at: 0)])
    #expect(episodes.map(\.start) == [Night.at(0), Night.at(3600)])
  }

  @Test func eventInsideAnotherDoesNotShortenTheEpisode() {
    let episodes = SnoringEpisodes.all(in: [Night.event(at: 0, duration: 600), Night.event(at: 100, duration: 60)])
    #expect(episodes.count == 1)
    #expect(episodes[0].duration == 600)
  }

  @Test func sleepTalkingDoesNotJoinSnoringEpisodes() {
    let snore = Night.event(at: 0, duration: 60)
    let talking = Night.event(at: 30, duration: 60, category: .sleepTalking)
    let episodes = SnoringEpisodes.all(in: [snore, talking])
    #expect(episodes.count == 1)
    #expect(episodes[0].events.map(\.id) == [snore.id])
  }

  @Test func episodesUnderThreeSecondsAreHidden() {
    let tooShort = Night.event(at: 0, duration: 2.9)
    let justEnough = Night.event(at: 3600, duration: 3)
    #expect(SnoringEpisodes.all(in: [tooShort, justEnough]).count == 2)
    #expect(SnoringEpisodes.displayable(in: [tooShort, justEnough]).map(\.id) == [justEnough.id])
  }

  @Test func eventCountIsDisplayableEpisodesPlusOtherEvents() {
    let session = Night.session(events: [
      Night.event(at: 0, duration: 60),
      Night.event(at: 120, duration: 60), // merges with the first
      Night.event(at: 3600, duration: 1), // hidden micro-episode
      Night.event(at: 7200, duration: 30, category: .sleepTalking),
    ])
    #expect(session.eventCount == 2)
  }

  @Test func representativeEventPlaysTheWholeEpisodeInOrder() {
    let first = Night.event(at: 0, duration: 30)
    let longest = Night.event(at: 100, duration: 120)
    let events = [longest, first]
    #expect(SnoringEpisodes.displayable(in: events).first?.representativeEvent.id == longest.id)
    #expect(SnoringEpisodes.playbackEvents(for: longest, in: events).map(\.id) == [first.id, longest.id])
  }

  @Test func nonRepresentativeAndNonSnoringEventsPlayAlone() {
    let first = Night.event(at: 0, duration: 30)
    let longest = Night.event(at: 100, duration: 120)
    let talking = Night.event(at: 7200, duration: 30, category: .sleepTalking)
    let events = [first, longest, talking]
    #expect(SnoringEpisodes.playbackEvents(for: first, in: events).map(\.id) == [first.id])
    #expect(SnoringEpisodes.playbackEvents(for: talking, in: events).map(\.id) == [talking.id])
  }

  @Test func measuredDurationUsesBurstsWhenPresent() throws {
    let withBursts = Night.event(
      at: 0, duration: 600,
      bursts: [SnoreBurst(startOffset: 0, endOffset: 20), SnoreBurst(startOffset: 100, endOffset: 130)])
    let withoutBursts = Night.event(at: 700, duration: 40)
    let episode = try #require(SnoringEpisodes.all(in: [withBursts, withoutBursts]).first)
    #expect(episode.snoreDuration == 640)
    #expect(episode.measuredDuration == 90) // 20 + 30 + 40
  }

  @Test func peakIsMaxAndAverageIsDurationWeighted() throws {
    let quiet = Night.event(at: 0, duration: 60, averageDB: -40, peakDB: -30)
    let loud = Night.event(at: 100, duration: 180, averageDB: -20, peakDB: -10)
    let episode = try #require(SnoringEpisodes.all(in: [quiet, loud]).first)
    #expect(episode.peakDB == -10)
    #expect(episode.averageDB == -25) // (−40 × 60 + −20 × 180) / 240
  }
}
