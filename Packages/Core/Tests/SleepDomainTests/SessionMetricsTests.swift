import Foundation
import SleepCore
import Testing
@testable import SleepDomain

/// Ported from SleepGuard's `SessionStatsTests` and `SleepScoreTests` (default
/// config): same inputs, same numbers, so both apps score a night identically.
/// The comments show the arithmetic.
struct SessionMetricsTests {
  // MARK: - Durations and stats

  @Test func gapsDurationSumsGaps() {
    let session = Night.session(gaps: [RecordingGap(startOffset: 0, duration: 600), RecordingGap(startOffset: 3600, duration: 1200)])
    #expect(session.gapsDuration == 1800)
  }

  @Test func snoringDurationIsTheSnoringEventSpans() {
    #expect(Night.session(events: [Night.event(at: 0, duration: 2880)]).snoringDuration == 2880)
  }

  @Test func sleepTalkingStatsCountOnlySleepTalking() {
    let session = Night.session(events: [
      Night.event(at: 0, duration: 60, category: .sleepTalking),
      Night.event(at: 600, duration: 84, category: .sleepTalking),
      Night.event(at: 1200, duration: 500),
    ])
    #expect(session.sleepTalkingEvents.count == 2)
    #expect(session.sleepTalkingDuration == 144)
    #expect(session.snoringDuration == 500)
  }

  @Test func stageStatsNilWithoutStageTime() {
    #expect(Night.session().stageStats == nil)
    #expect(Night.session(stages: [SleepStageSegment(stage: .deep, startOffset: 0, duration: 0)]).stageStats == nil)
  }

  @Test func stageStatsArePercentagesOfStageTotal() throws {
    let session = Night.session(stages: [
      SleepStageSegment(stage: .deep, startOffset: 0, duration: 30),
      SleepStageSegment(stage: .light, startOffset: 30, duration: 40),
      SleepStageSegment(stage: .rem, startOffset: 70, duration: 10),
      SleepStageSegment(stage: .deep, startOffset: 80, duration: 10),
      SleepStageSegment(stage: .awake, startOffset: 90, duration: 10),
    ])
    let stats = try #require(session.stageStats)
    #expect((stats.deepPct, stats.lightPct, stats.remPct, stats.awakePct) == (40, 40, 10, 10))
  }

  @Test func summaryCarriesScoreSnoringAndEvents() {
    let session = Night.session(events: [Night.event(at: 3600, duration: 2880, intensity: .light)])
    let summary = session.summary()
    #expect(summary.id == session.id)
    #expect(summary.score == 82)
    #expect(summary.snoringDuration == 2880)
    #expect(summary.eventCount == 1)
    #expect(summary.duration == 8 * 3600)
  }

  // MARK: - Score: baseline and duration

  @Test func cleanEightHourNightScoresMax() {
    #expect(Night.session().score() == 100)
  }

  @Test func customConfigMaxScoreIsUsed() {
    #expect(Night.session().score(using: SleepScoreConfig(maxScore: 50)) == 50)
  }

  @Test func shortNightIsPenalized() {
    // (6 h threshold − 4 h) × 2 = 4
    #expect(Night.session(hours: 4).score() == 96)
  }

  @Test func sessionUnderThreeHoursHasNoShortSleepPenalty() {
    #expect(Night.session(hours: 2).score() == 100)
  }

  @Test func longNightIsPenalizedAndCapped() {
    // (11 h − 9 h) × 1 = 2; (15 h − 9 h) × 1 = 6 → cap 5
    #expect(Night.session(hours: 11).score() == 98)
    #expect(Night.session(hours: 15).score() == 95)
  }

  // MARK: - Score: snoring and intensity

  @Test func tenPercentLightSnoring() {
    // snoring 2880 / 28800 = 10 % × 0.85 = 8; events 1/8 h × 2.5 = 0; light ratio 1 × 10 = 10
    #expect(Night.session(events: [Night.event(at: 3600, duration: 2880, intensity: .light)]).score() == 82)
  }

  @Test func intensityPenaltyIsCapped() {
    // snoring 8; epic ratio 1 × 40 = 40 → cap 30
    #expect(Night.session(events: [Night.event(at: 3600, duration: 2880, intensity: .epic)]).score() == 62)
  }

  @Test func scoreNeverDropsBelowMin() {
    // snoring 100 % × 0.85 = 85 → cap 75; epic → cap 30; 100 − 105 → clamp 0
    #expect(Night.session(events: [Night.event(at: 0, duration: 28800, intensity: .epic)]).score() == 0)
  }

  @Test func intensityRatiosUseBurstSumNotEventSpan() {
    // Light spans 600 s with 60 s of bursts; epic 60 s, no bursts. Measured 120 s:
    // light 0.5 × 10 + epic 0.5 × 40 = 25. Snoring 660 / 28800 = 2.3 % × 0.85 = 1.
    let light = Night.event(
      at: 3600, duration: 600, intensity: .light,
      bursts: [SnoreBurst(startOffset: 0, endOffset: 30), SnoreBurst(startOffset: 300, endOffset: 330)])
    let epic = Night.event(at: 4 * 3600, duration: 60, intensity: .epic)
    #expect(Night.session(events: [light, epic]).score() == 74)
  }

  // MARK: - Score: events per hour

  @Test func manyEpisodesArePenalized() {
    // 20 quiet 10 s events, 20 min apart → 20 episodes / 8 h × 2.5 = 6
    let events = (0..<20).map { Night.event(at: Double($0) * 1200, duration: 10, intensity: .quiet) }
    #expect(Night.session(events: events).score() == 94)
  }

  @Test func microEpisodesDoNotCountAsEvents() {
    let events = (0..<20).map { Night.event(at: Double($0) * 1200, duration: 2, intensity: .quiet) }
    #expect(Night.session(events: events).score() == 100)
  }

  @Test func eventsWithinFiveMinutesMergeIntoOneEpisode() {
    let events = (0..<20).map { Night.event(at: Double($0) * 120, duration: 10, intensity: .quiet) }
    #expect(Night.session(events: events).score() == 100)
  }

  // MARK: - Score: recording gaps

  @Test func gapWhereSnoringResumedCountsAsSnoring() {
    // Uncovered gap: (60 + 2880) / 28800 = 10.2 % × 0.85 = 8
    let session = Night.session(
      events: [Night.event(at: 0, duration: 60, intensity: .quiet)],
      gaps: [RecordingGap(startOffset: 7200, duration: 2880)])
    #expect(session.snoringDuration == 2940)
    #expect(session.score() == 92)
  }

  @Test func gapWhereSnoringDidNotResumeIsIgnored() {
    let session = Night.session(
      events: [Night.event(at: 0, duration: 60, intensity: .quiet)],
      gaps: [RecordingGap(startOffset: 7200, duration: 2880, snoringResumed: false)])
    #expect(session.score() == 100)
  }

  @Test func gapInsideAnEventIsNotDoubleCounted() {
    // Event 0–3000 s covers the gap 600–1800 s → snoring stays 3000 s → 8
    let session = Night.session(
      events: [Night.event(at: 0, duration: 3000, intensity: .quiet)],
      gaps: [RecordingGap(startOffset: 600, duration: 1200)])
    #expect(session.snoringDuration == 3000)
    #expect(session.score() == 92)
  }

  // MARK: - Score: sleep talking and stages

  @Test func sleepTalkingIsPenalized() {
    // 40 × 60 s: 8.33 % × 0.35 = 2.9 + 5/h × 0.8 = 4 → 6
    let events = (0..<40).map { Night.event(at: Double($0) * 600, duration: 60, intensity: .quiet, category: .sleepTalking) }
    #expect(Night.session(events: events).score() == 94)
  }

  @Test func missingDeepAndRemIsPenalizedAndCapped() {
    // deep (15 − 0) × 0.6 = 9 + REM (18 − 0) × 0.4 = 7.2 → 16 → cap 15
    #expect(Night.session(stages: [SleepStageSegment(stage: .light, startOffset: 0, duration: 28800)]).score() == 85)
  }

  @Test func healthyStagesHaveNoPenalty() {
    let session = Night.session(stages: [
      SleepStageSegment(stage: .deep, startOffset: 0, duration: 20),
      SleepStageSegment(stage: .rem, startOffset: 20, duration: 25),
      SleepStageSegment(stage: .awake, startOffset: 45, duration: 5),
      SleepStageSegment(stage: .light, startOffset: 50, duration: 50),
    ])
    #expect(session.score() == 100)
  }
}
