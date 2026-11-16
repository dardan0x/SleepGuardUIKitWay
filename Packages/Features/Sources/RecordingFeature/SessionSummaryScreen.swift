import SleepCore
import SleepGuardDesignKit
import SwiftUI

/// The night just recorded: how long, its score, snoring share and events,
/// the banners that explain gaps, its timeline, then Save or Discard. A night
/// under `Night.minimumSaveDuration` can't be saved, as in SleepGuard.
public struct SessionSummaryScreen: View {
  let night: Night
  let scoreConfig: SleepScoreConfig
  let routes: SessionSummaryRoutes
  @State private var showingTooShort = false
  @Environment(\.theme) private var theme

  public init(night: Night, scoreConfig: SleepScoreConfig = .default, routes: SessionSummaryRoutes) {
    self.night = night
    self.scoreConfig = scoreConfig
    self.routes = routes
  }

  public var body: some View {
    let summary = night.summary(using: scoreConfig)
    ScrollView {
      VStack(spacing: 32) {
        SessionSummaryHeader(
          duration: night.duration, score: summary.score, snoringPercent: summary.snoringShare * 100,
          eventCount: summary.eventCount)
        if !night.recordingGaps.isEmpty {
          RecordingGapsBanner(totalGap: night.gapsDuration)
        }
        if night.endReason == .lowBattery {
          LowBatteryBanner()
        }
        NightTimeline(night: night, showsTitle: false)
        SessionSummaryActions(onSave: saveTapped, onDiscard: { routes.discard(night) })
      }
      .padding(24)
    }
    .background(theme.palette.bgPrimary.ignoresSafeArea())
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
