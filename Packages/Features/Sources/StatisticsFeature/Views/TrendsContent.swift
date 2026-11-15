import SleepCore
import SleepGuardDesignKit
import SwiftUI

/// The week or month picker, average snoring, a bar per night, and four stats.
struct TrendsContent: View {
  enum Range: CaseIterable {
    case week
    case month

    var days: Int {
      self == .week ? 7 : 30
    }

    var title: String {
      self == .week ? Strings.statsTrendsWeek : Strings.statsTrendsMonth
    }
  }

  let nights: [NightSummary]
  let now: Date
  @State private var range = Range.week
  @Environment(\.theme) private var theme

  var body: some View {
    let period = NightPeriod(lastDays: range.days, of: nights, now: now)
    VStack(spacing: 24) {
      PillPicker(options: Range.allCases, selection: $range, title: \.title)

      VStack(alignment: .leading, spacing: 4) {
        Text(Strings.statsTrendsAvgSnoringLabel)
          .font(theme.typography.font(size: 11, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(1)
        HStack(alignment: .lastTextBaseline, spacing: 6) {
          Text(DurationText.hoursAndMinutes(TimeInterval(period.averageSnoringMinutes * 60)))
            .font(theme.typography.font(size: 36, weight: .bold))
            .foregroundStyle(theme.palette.textPrimary)
          Text(Strings.statsTrendsAvgMinFormat)
            .font(theme.typography.font(size: 14))
            .foregroundStyle(theme.palette.textSecondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      SnoringBarChart(bars: period.nights.map { night in
        SnoringBar(
          id: night.id,
          label: range == .week
            ? night.start.formatted(.dateTime.weekday(.abbreviated))
            : night.start.formatted(.dateTime.day()),
          minutes: Int(night.snoringDuration / 60),
          intensity: night.loudestIntensity ?? .quiet)
      })

      SnoringLegend()

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatTile(icon: "scope", iconColor: theme.palette.accent, label: Strings.statsTrendsStatCardAvgScore, value: "\(period.averageScore)")
        StatTile(icon: "star.fill", iconColor: theme.palette.scoreGreen, label: Strings.statsTrendsStatCardBestNight, value: "\(period.bestScore)")
        StatTile(icon: "bolt.fill", iconColor: theme.palette.snoreLoud, label: Strings.statsTrendsStatCardWorstNight, value: "\(period.worstScore)")
        StatTile(icon: "number", iconColor: theme.palette.textTertiary, label: Strings.statsTrendsStatCardTotalEvents, value: "\(period.eventCount)")
      }
    }
    .padding(20)
  }
}
