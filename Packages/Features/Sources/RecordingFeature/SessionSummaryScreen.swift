import SleepCore
import SleepGuardContentKit
import SwiftUI

/// The night just recorded: how long, its score, snoring share and events,
/// the banners that explain gaps, its timeline, then Save or Discard. A night
/// under `Night.minimumSaveDuration` can't be saved, as in SleepGuard.
public struct SessionSummaryScreen: View {
  let night: Night
  let scoreConfig: SleepScoreConfig
  let routes: SessionSummaryRoutes
  @State private var showingTooShort = false

  public init(night: Night, scoreConfig: SleepScoreConfig = .default, routes: SessionSummaryRoutes) {
    self.night = night
    self.scoreConfig = scoreConfig
    self.routes = routes
  }

  public var body: some View {
    SessionSummaryContent(
      night: night, summary: night.summary(using: scoreConfig), onSave: saveTapped, onDiscard: { routes.discard(night) })
      .alert(Strings.sessionSummaryTooShortTitle, isPresented: $showingTooShort) {
        Button(Strings.actionOk, role: .cancel) {}
      } message: {
        Text(String(format: Strings.sessionSummaryTooShortInfoFormat, Int(Night.minimumSaveDuration / 60)))
      }
  }

  private func saveTapped() {
    if night.duration < Night.minimumSaveDuration {
      showingTooShort = true
    } else {
      routes.save(night)
    }
  }
}
