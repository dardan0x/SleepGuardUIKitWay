import SleepCore
import SleepDomain

public struct StatisticsDependencies: Sendable {
  public var nights: any SessionRepository
  /// Whether the dashboard asks for the profile now (SleepCore's
  /// `ProfilePrompt`, decided once per appearance).
  public var asksForProfile: @MainActor @Sendable () async -> Bool

  public init(nights: any SessionRepository, asksForProfile: @escaping @MainActor @Sendable () async -> Bool = { false }) {
    self.nights = nights
    self.asksForProfile = asksForProfile
  }
}

public struct StatisticsRoutes {
  public var startRecording: @MainActor () -> Void
  /// "View month": Trends.
  public var showTrends: @MainActor () -> Void
  /// The Calendar button in the title row.
  public var showCalendar: @MainActor () -> Void
  /// "See all" on the 7-night chart.
  public var showLastSevenNights: @MainActor () -> Void
  /// The info button on the latest night's sleep stages: the stages sheet.
  public var showStagesInfo: @MainActor (SleepStageBreakdown) -> Void
  /// The profile prompt's Set Up: the profile editor.
  public var openProfile: @MainActor () -> Void
  /// The profile prompt was dismissed (its chance halves next time).
  public var dismissProfilePrompt: @MainActor () -> Void

  public init(
    startRecording: @escaping @MainActor () -> Void,
    showTrends: @escaping @MainActor () -> Void,
    showCalendar: @escaping @MainActor () -> Void,
    showLastSevenNights: @escaping @MainActor () -> Void,
    showStagesInfo: @escaping @MainActor (SleepStageBreakdown) -> Void,
    openProfile: @escaping @MainActor () -> Void,
    dismissProfilePrompt: @escaping @MainActor () -> Void)
  {
    self.startRecording = startRecording
    self.showTrends = showTrends
    self.showCalendar = showCalendar
    self.showLastSevenNights = showLastSevenNights
    self.showStagesInfo = showStagesInfo
    self.openProfile = openProfile
    self.dismissProfilePrompt = dismissProfilePrompt
  }
}
