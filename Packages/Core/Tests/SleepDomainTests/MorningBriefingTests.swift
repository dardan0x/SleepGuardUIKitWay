import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

/// The briefing is due once per new night, off when turned off; closing it
/// is remembered; a survey answer is kept for its night and not asked again.
struct MorningBriefingTests {
  let now = Date(timeIntervalSinceReferenceDate: 815_000_000)
  var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }

  func night(daysAgo: Double, score: Int = 80) -> Night {
    let start = now.addingTimeInterval(-daysAgo * 86400 - 8 * 3600)
    return Night(start: start, end: start.addingTimeInterval(7 * 3600), events: [
      NightEvent(start: start.addingTimeInterval(600), duration: Double(score), intensity: .light),
    ])
  }

  func make(
    nights: [Night], preferences: AppPreferences = AppPreferences(), logs: FakeLifestyleLogStore = FakeLifestyleLogStore())
    -> (MorningBriefing, FakePreferencesStore)
  {
    let store = FakePreferencesStore(preferences)
    let briefing = MorningBriefing(
      nights: FakeSessionRepository(nights), profiles: FakeProfileStore(), logs: logs, preferences: store, calendar: calendar)
    return (briefing, store)
  }

  @Test func aNewNightIsDueOnceUntilShown() async {
    let (briefing, _) = make(nights: [night(daysAgo: 1), night(daysAgo: 2)])
    let due = await briefing.due(now: now)
    #expect(due != nil)
    #expect(due?.briefing.stats.isEmpty == false)
    await briefing.markShown(at: now)
    #expect(await briefing.due(now: now) == nil)
  }

  @Test func turnedOffOrNoNightsIsNeverDue() async {
    var off = AppPreferences()
    off.briefingEnabled = false
    #expect(await make(nights: [night(daysAgo: 1)], preferences: off).0.due(now: now) == nil)
    #expect(await make(nights: []).0.due(now: now) == nil)
  }

  @Test func anAnswerIsKeptAndTheSurveyIsNotAskedAgain() async throws {
    let logs = FakeLifestyleLogStore()
    let (briefing, _) = make(nights: [night(daysAgo: 1), night(daysAgo: 2)], logs: logs)
    let due = try #require(await briefing.due(now: now))
    #expect(due.briefing.survey != nil)
    try await briefing.answer(.exercised, for: due.night)
    #expect(await logs.saved == [LifestyleLog(night: due.night.start, chips: [.exercised])])
    #expect(await briefing.due(now: now)?.briefing.survey == nil)
  }
}

/// The profile prompt asks after three full nights with a thin profile, and
/// each dismissal is counted.
struct ProfilePromptCheckTests {
  func nights(_ count: Int) -> [Night] {
    (0..<count).map { index in
      let start = Date(timeIntervalSinceReferenceDate: 815_000_000 - Double(index) * 86400)
      return Night(start: start, end: start.addingTimeInterval(7 * 3600))
    }
  }

  @Test func asksAfterThreeFullNightsAndCountsDismissals() async {
    let preferences = FakePreferencesStore()
    let check = ProfilePromptCheck(nights: FakeSessionRepository(nights(3)), profiles: FakeProfileStore(), preferences: preferences)
    #expect(await check.shouldAsk(roll: 0.9, coin: true))
    await check.dismissed()
    #expect(await preferences.load().profilePromptDismissCount == 1)
    #expect(!(await check.shouldAsk(roll: 0.9, coin: true)))
  }

  @Test func notBeforeThreeNights() async {
    let check = ProfilePromptCheck(nights: FakeSessionRepository(nights(2)), profiles: FakeProfileStore(), preferences: FakePreferencesStore())
    #expect(!(await check.shouldAsk(roll: 0, coin: true)))
  }
}
