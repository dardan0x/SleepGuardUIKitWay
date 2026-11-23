import Foundation
import SleepCore

/// The morning briefing, when it's due: a new night is waiting (SleepCore's
/// `BriefingSchedule`) and the person hasn't turned it off. SleepCore's
/// `BriefingEngine` builds it from the nights, the profile and the survey
/// answers. Marking it shown and keeping an answer are plain port writes, done
/// by the caller.
public struct LoadMorningBriefing: Sendable {
  /// A briefing to show, and the night it's about.
  public struct Due: Equatable, Sendable {
    public let briefing: Briefing
    public let night: NightSummary
  }

  private let nights: any SessionRepository
  private let profiles: any ProfileStore
  private let logs: any LifestyleLogStore
  private let preferences: any PreferencesStore
  private let calendar: Calendar

  public init(
    nights: any SessionRepository, profiles: any ProfileStore, logs: any LifestyleLogStore,
    preferences: any PreferencesStore, calendar: Calendar = .current)
  {
    self.nights = nights
    self.profiles = profiles
    self.logs = logs
    self.preferences = preferences
    self.calendar = calendar
  }

  /// The briefing, or `nil` when none is due.
  public func callAsFunction(now: Date = Date()) async -> Due? {
    let stored = await preferences.load()
    guard stored.briefingEnabled else { return nil }
    let summaries = await currentSummaries()
    guard let latest = summaries.max(by: { $0.start < $1.start }),
          BriefingSchedule.isDue(latest: latest, lastShown: stored.lastBriefingShown, now: now, calendar: calendar)
    else { return nil }
    let briefing = await BriefingEngine.make(
      nights: summaries, profile: profiles.load(), logs: logs.logs(), now: now, calendar: calendar)
    return Due(briefing: briefing, night: latest)
  }

  private func currentSummaries() async -> [NightSummary] {
    for await summaries in await nights.observeSummaries() {
      return summaries
    }
    return []
  }
}
