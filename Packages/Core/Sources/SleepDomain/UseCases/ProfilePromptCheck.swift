import Foundation
import SleepCore

/// Whether the dashboard asks for the profile (SleepCore's `ProfilePrompt`:
/// three full nights, a profile under half complete, a chance that halves
/// with each dismissal), and remembering a dismissal.
public struct ProfilePromptCheck: Sendable {
  private let nights: any SessionRepository
  private let profiles: any ProfileStore
  private let preferences: any PreferencesStore

  public init(nights: any SessionRepository, profiles: any ProfileStore, preferences: any PreferencesStore) {
    self.nights = nights
    self.profiles = profiles
    self.preferences = preferences
  }

  /// `roll` in 0..<1 and `coin` are drawn by the caller, once per appearance.
  public func shouldAsk(roll: Double = .random(in: 0..<1), coin: Bool = .random()) async -> Bool {
    var summaries: [NightSummary] = []
    for await current in await nights.observeSummaries() {
      summaries = current
      break
    }
    let fullNights = summaries.filter { $0.duration >= Night.minimumSaveDuration }.count
    return await ProfilePrompt.shouldShow(
      fullNights: fullNights, completion: profiles.load().completion,
      dismissCount: preferences.load().profilePromptDismissCount, roll: roll, coin: coin)
  }

  public func dismissed() async {
    var stored = await preferences.load()
    stored.profilePromptDismissCount += 1
    await preferences.save(stored)
  }
}
