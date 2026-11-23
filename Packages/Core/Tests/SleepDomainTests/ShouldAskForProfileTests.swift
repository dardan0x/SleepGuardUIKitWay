import Foundation
import SleepCore
import SleepDomainTestSupport
import Testing
@testable import SleepDomain

/// The profile prompt asks after three full nights with a thin profile, and
/// a counted dismissal lowers the chance.
struct ShouldAskForProfileTests {
  func nights(_ count: Int) -> [Night] {
    (0..<count).map { index in
      let start = Date(timeIntervalSinceReferenceDate: 815_000_000 - Double(index) * 86400)
      return Night(start: start, end: start.addingTimeInterval(7 * 3600))
    }
  }

  @Test func asksAfterThreeFullNightsUntilDismissed() async {
    let preferences = FakePreferencesStore()
    let shouldAsk = ShouldAskForProfile(
      nights: FakeSessionRepository(nights(3)), profiles: FakeProfileStore(), preferences: preferences)
    #expect(await shouldAsk(roll: 0.9, coin: true))
    var dismissed = await preferences.load()
    dismissed.profilePromptDismissCount += 1
    await preferences.save(dismissed)
    #expect(await !shouldAsk(roll: 0.9, coin: true))
  }

  @Test func notBeforeThreeNights() async {
    let shouldAsk = ShouldAskForProfile(
      nights: FakeSessionRepository(nights(2)), profiles: FakeProfileStore(), preferences: FakePreferencesStore())
    #expect(await !shouldAsk(roll: 0, coin: true))
  }
}
