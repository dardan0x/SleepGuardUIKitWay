import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SwiftUI

/// Score gauge, four stats, and a disturbances card when there are any.
struct SessionDetailHeader: View {
  let detail: SessionDetail
  @Environment(\.theme) private var theme

  var body: some View {
    let night = detail.session
    let disturbances = night.events.filter { $0.category != .snoring }.count
    let snoringShare = night.duration > 0 ? detail.summary.snoringDuration / night.duration : 0

    VStack(spacing: 12) {
      HStack(spacing: 16) {
        SleepScoreGauge(score: detail.summary.score, size: 120)

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
          StatCard(icon: "clock", title: Strings.recordingsPlayerStatDuration, value: Self.hoursMinutes(night.duration))
          StatCard(
            icon: "percent", title: Strings.sessionSummaryStatSnoring,
            value: snoringShare.formatted(.percent.precision(.fractionLength(0))), iconColor: theme.palette.scoreAmber)
          StatCard(
            icon: "waveform", title: Strings.sessionSummaryStatSnoreTime,
            value: Self.hoursMinutes(detail.summary.snoringDuration), iconColor: theme.palette.scoreRed)
          StatCard(
            icon: "bolt.fill", title: Strings.recordingsDetailEventsLabel,
            value: "\(detail.summary.eventCount)", iconColor: theme.palette.scoreAmber)
        }
      }

      if disturbances > 0 {
        StatCard(icon: "speaker.wave.2.fill", title: Strings.sessionDisturbances, value: "\(disturbances)", iconColor: theme.palette.noise)
      }
    }
  }

  static func hoursMinutes(_ interval: TimeInterval) -> String {
    Duration.seconds(interval).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
  }
}
