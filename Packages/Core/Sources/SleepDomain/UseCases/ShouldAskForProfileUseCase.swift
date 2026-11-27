import Foundation
import SleepCore

/// Whether the dashboard asks for the profile (SleepCore's `ProfilePrompt`:
/// three full nights, a profile under half complete, a chance that halves
/// with each dismissal). Counting a dismissal is a plain preferences write,
/// done by the caller.
public struct ShouldAskForProfileUseCase: Sendable {
  private let nights: any SessionRepositoryPort
  private let profiles: any ProfileStorePort
  private let preferences: any PreferencesStorePort
  private let saveRules: SaveRules

  public init(
    nights: any SessionRepositoryPort,
    profiles: any ProfileStorePort,
    preferences: any PreferencesStorePort,
    saveRules: SaveRules = .standard)
  {
    self.nights = nights
    self.profiles = profiles
    self.preferences = preferences
    self.saveRules = saveRules
  }

  /// `roll` in 0..<1 and `coin` are drawn by the caller, once per appearance.
  public func callAsFunction(roll: Double = .random(in: 0..<1), coin: Bool = .random()) async -> Bool {
    var summaries: [NightSummary] = []
    for await current in await nights.observeSummaries() {
      summaries = current
      break
    }
    let fullNights = summaries.filter { saveRules.isLongEnough($0.duration) }.count
    return await ProfilePrompt.shouldShow(
      fullNights: fullNights, completion: profiles.load().completion,
      dismissCount: preferences.load().profilePromptDismissCount, roll: roll, coin: coin)
  }
}
