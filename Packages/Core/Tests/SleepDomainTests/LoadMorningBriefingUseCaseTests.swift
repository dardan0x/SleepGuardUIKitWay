import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

/// The briefing is due once per new night, off when turned off; once shown it
/// isn't due again; a kept survey answer means the survey isn't asked again.
struct LoadMorningBriefingUseCaseTests {
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
    nights: [Night], preferences: FakePreferencesStore = FakePreferencesStore(),
    logs: FakeLifestyleLogStore = FakeLifestyleLogStore()) -> LoadMorningBriefingUseCase
  {
    LoadMorningBriefingUseCase(
      nights: FakeSessionRepository(nights), profiles: FakeProfileStore(), logs: logs, preferences: preferences,
      calendar: calendar)
  }

  @Test func aNewNightIsDueUntilShown() async {
    let preferences = FakePreferencesStore()
    let load = make(nights: [night(daysAgo: 1), night(daysAgo: 2)], preferences: preferences)
    let due = await load(now: now)
    #expect(due != nil)
    #expect(due?.briefing.stats.isEmpty == false)
    var shown = await preferences.load()
    shown.lastBriefingShown = now
    await preferences.save(shown)
    #expect(await load(now: now) == nil)
  }

  @Test func turnedOffOrNoNightsIsNeverDue() async {
    var off = AppPreferences()
    off.briefingEnabled = false
    #expect(await make(nights: [night(daysAgo: 1)], preferences: FakePreferencesStore(off))(now: now) == nil)
    #expect(await make(nights: [])(now: now) == nil)
  }

  @Test func aKeptAnswerMeansTheSurveyIsNotAskedAgain() async throws {
    let logs = FakeLifestyleLogStore()
    let load = make(nights: [night(daysAgo: 1), night(daysAgo: 2)], logs: logs)
    let due = try #require(await load(now: now))
    #expect(due.briefing.survey != nil)
    try await logs.save(LifestyleLog(night: due.night.start, chips: [.exercised]))
    #expect(await load(now: now)?.briefing.survey == nil)
  }
}
