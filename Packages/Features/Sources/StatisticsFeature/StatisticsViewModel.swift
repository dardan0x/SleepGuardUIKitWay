import Foundation
import Observation
import SleepCore
import SleepDomain

/// The dashboard's state and intents: the nights live as SleepCore's
/// `NightDashboard`, the latest night's sleep stages, and the profile prompt.
@MainActor
@Observable
public final class StatisticsViewModel {
  public enum State {
    case loading
    case empty
    /// `now`: when the dashboard was made, for "last night" and the week strip.
    case loaded(NightDashboard, now: Date)
  }

  public private(set) var state: State = .loading
  public private(set) var asksForProfile = false
  /// The latest night's stages, once read; `nil` while reading or without any.
  public private(set) var latestStages: SleepStageBreakdown?
  private var stagesOf: NightSummary?
  let dependencies: StatisticsDependencies
  let routes: StatisticsRoutes

  public init(dependencies: StatisticsDependencies, routes: StatisticsRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  /// Follows the nights until cancelled. The dashboard is built from
  /// summaries (no stages), so the latest night is read again whenever its
  /// summary changes (stages added on opening it change its score).
  public func observe() async {
    for await nights in await dependencies.nights.observeSummaries() {
      let now = Date()
      guard let dashboard = NightDashboard.make(from: nights, now: now) else {
        state = .empty
        continue
      }
      state = .loaded(dashboard, now: now)
      await readStages(of: dashboard.latest)
    }
  }

  /// Decided once per appearance.
  public func checkProfilePrompt() async {
    let asks = await dependencies.asksForProfile()
    if !Task.isCancelled { asksForProfile = asks }
  }

  public func answerProfilePrompt(open: Bool) {
    asksForProfile = false
    if open { routes.openProfile() } else { routes.dismissProfilePrompt() }
  }

  public func startRecording() {
    routes.startRecording()
  }

  public func showTrends() {
    routes.showTrends()
  }

  public func showCalendar() {
    routes.showCalendar()
  }

  public func showLastSevenNights() {
    routes.showLastSevenNights()
  }

  public func showStagesInfo(_ stages: SleepStageBreakdown) {
    routes.showStagesInfo(stages)
  }

  private func readStages(of latest: NightSummary) async {
    guard stagesOf != latest else { return }
    stagesOf = latest
    latestStages = nil
    let night = try? await dependencies.nights.session(id: latest.id)
    guard !Task.isCancelled, stagesOf == latest else { return }
    latestStages = night.flatMap { SleepStageBreakdown(segments: $0.sleepStages) }
  }
}
