import SleepCore
import SleepGuardDesignKit
import SwiftUI

struct StatisticsLoadedView: View {
  let dashboard: NightDashboard
  let now: Date
  let routes: StatisticsRoutes

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        StatisticsDashboardContent(dashboard: dashboard, now: now, routes: routes)
          .padding(.horizontal, 20)
      }
      StartRecordingButton(height: 56, action: routes.startRecording)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
  }
}

/// The scrolling content, separate so it can be rendered in tests.
struct StatisticsDashboardContent: View {
  let dashboard: NightDashboard
  let now: Date
  let routes: StatisticsRoutes
  @Environment(\.theme) private var theme

  var body: some View {
    let night = dashboard.latest
    VStack(spacing: 16) {
      VStack(spacing: 8) {
        HStack {
          Text(Strings.statsTrendsThisWeekLabel)
            .font(theme.typography.font(size: 12, weight: .semibold))
            .foregroundStyle(theme.palette.textTertiary)
            .tracking(1)
          Spacer()
          Button(Strings.statsTrendsViewMonth, action: routes.showTrends)
            .font(theme.typography.font(size: 14, weight: .medium))
            .foregroundStyle(theme.palette.accent)
        }
        WeekStrip(days: dashboard.week(now: now))
      }

      SleepScoreGauge(score: dashboard.dayScore, size: 120)

      VStack(spacing: 4) {
        Text(summaryLabel)
          .font(theme.typography.font(size: 12, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(1)
        Text("\(night.start.formatted(.dateTime.month(.abbreviated).day())) · \(Self.times(night))")
          .font(theme.typography.font(size: 15))
          .foregroundStyle(theme.palette.textSecondary)
      }

      SessionStatsGrid(
        duration: night.duration, snoringShare: night.snoringShare,
        snoreTime: night.snoringDuration, eventCount: night.eventCount)

      StatisticsWeekChart(nights: dashboard.recent, onSeeAll: routes.showLastSevenNights)
    }
    .padding(.vertical, 10)
  }

  /// "LAST NIGHT", "LAST TIME", or "2 RECORDINGS" when the day had several.
  private var summaryLabel: String {
    if dashboard.dayNightCount > 1 {
      return "\(dashboard.dayNightCount) \(Strings.recordingsStatisticsLoadedView)"
    }
    return dashboard.isLastNight ? Strings.lastNightStatisticsLoadedView : Strings.lastTimeStatisticsLoadedView
  }

  static func times(_ night: NightSummary) -> String {
    "\(night.start.formatted(date: .omitted, time: .shortened)) – \(night.end.formatted(date: .omitted, time: .shortened))"
  }
}

/// "Last 7 Nights": one bar per day's average score (SleepCore's `NightDay`).
struct StatisticsWeekChart: View {
  let nights: [NightSummary]
  let onSeeAll: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(Strings.statsTrendsLastSevenNights)
          .font(theme.typography.font(size: 20, weight: .bold))
          .foregroundStyle(theme.palette.textPrimary)
        Spacer()
        Button(Strings.statsTrendsSeeAll, action: onSeeAll)
          .font(theme.typography.font(size: 14, weight: .medium))
          .foregroundStyle(theme.palette.accent)
      }
      MiniBarChart(data: NightDay.days(from: nights).map { day in
        MiniBarChart.DataPoint(
          label: String(day.date.formatted(.dateTime.weekday(.narrow))),
          value: Double(day.averageScore),
          color: theme.scoreColor(day.averageScore),
          accessibilityLabel: day.date.formatted(.dateTime.weekday(.wide)),
          accessibilityValue: String(format: Strings.a11yScoreOutOf100, day.averageScore))
      })
    }
    .padding(12)
  }
}
