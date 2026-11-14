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

        SessionStatsGrid(
          duration: night.duration, snoringShare: snoringShare,
          snoreTime: detail.summary.snoringDuration, eventCount: detail.summary.eventCount)
      }

      if disturbances > 0 {
        StatCard(icon: "speaker.wave.2.fill", title: Strings.sessionDisturbances, value: "\(disturbances)", iconColor: theme.palette.noise)
      }
    }
  }
}
