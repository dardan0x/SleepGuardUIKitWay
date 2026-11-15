import SleepCore
import SleepGuardDesignKit
import SwiftUI

struct LastSevenNightsContent: View {
  let nights: [NightSummary]
  let onOpen: (NightSummary) -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    let stats = NightDayStats.recent(from: nights)
    VStack(spacing: 16) {
      LastSevenNightsHeader(stats: stats, trend: ScoreTrend.weekOverWeek(nights))

      SnoringDayBars(bars: stats.days.map { day in
        SnoringBar(
          label: day.date.formatted(.dateTime.weekday(.narrow)), minutes: day.snoringMinutes,
          intensity: day.loudestIntensity)
      })

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
        StatTile(
          icon: "percent", iconColor: theme.palette.scoreAmber, label: Strings.statsLast7nightsAvgSnoring,
          value: DurationText.hoursAndMinutes(TimeInterval(stats.averageSnoringMinutes * 60)), valueSize: 22)
        StatTile(
          icon: "bolt.fill", iconColor: theme.palette.scoreAmber, label: Strings.statsLast7nightsTotalEvents,
          value: "\(stats.eventCount)", valueSize: 22)
        StatTile(
          icon: "leaf.fill", iconColor: theme.palette.scoreGreen, label: Strings.statsLast7nightsBest,
          value: Self.scoreAndDay(stats.best), valueSize: 22, valueColor: theme.palette.scoreGreen)
        StatTile(
          icon: "flame.fill", iconColor: theme.palette.scoreRed, label: Strings.statsLast7nightsWorst,
          value: Self.scoreAndDay(stats.worst), valueSize: 22, valueColor: theme.palette.scoreRed)
      }

      VStack(alignment: .leading, spacing: 12) {
        Text(Strings.statsLast7nightsAllNights)
          .font(theme.typography.font(size: 13, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(0.5)
        VStack(spacing: 8) {
          ForEach(stats.days.reversed()) { day in
            DayRow(
              score: day.averageScore, date: day.date, duration: day.duration,
              snoringMinutes: day.snoringMinutes, loudest: day.loudestIntensity)
            {
              if let night = day.nights.first { onOpen(night) }
            }
          }
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
  }

  /// "91 Tue"; "0" without days, as SleepGuard shows it.
  static func scoreAndDay(_ day: NightDay?) -> String {
    guard let day else { return "0 " }
    return "\(day.averageScore) \(day.date.formatted(.dateTime.weekday(.abbreviated)))"
  }
}

/// The days' range, the average score, and the trend against the week before.
struct LastSevenNightsHeader: View {
  let stats: NightDayStats
  let trend: ScoreTrend?
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(range)
        .font(theme.typography.font(size: 12, weight: .semibold))
        .foregroundStyle(theme.palette.textTertiary)
        .tracking(1)
      HStack(alignment: .lastTextBaseline, spacing: 12) {
        Text("\(stats.averageScore)")
          .font(theme.typography.font(size: 52, weight: .bold))
          .foregroundStyle(theme.palette.textPrimary)
        VStack(alignment: .leading, spacing: 4) {
          Text(Strings.statsLast7nightsAvgSleepScore)
            .font(theme.typography.font(size: 13))
            .foregroundStyle(theme.palette.textSecondary)
          if let trend {
            HStack(spacing: 4) {
              Image(systemName: trend.isPositive ? "arrow.up.forward" : "arrow.down.forward")
                .font(.system(size: 12, weight: .semibold))
                .accessibilityHidden(true)
              Text(String(format: Strings.statsLast7nightsTrendVsPrevWeek, trend.diff))
                .font(theme.typography.font(size: 12, weight: .medium))
            }
            .foregroundStyle(trend.isPositive ? theme.palette.scoreGreen : theme.palette.scoreRed)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// "NOV 7 – NOV 13"; empty without days.
  private var range: String {
    guard let first = stats.days.first?.date, let last = stats.days.last?.date else { return "" }
    let format = Date.FormatStyle.dateTime.month(.abbreviated).day()
    return "\(first.formatted(format)) – \(last.formatted(format))".uppercased()
  }
}
