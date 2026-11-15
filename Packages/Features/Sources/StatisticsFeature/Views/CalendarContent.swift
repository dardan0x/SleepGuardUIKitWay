import SleepCore
import SleepGuardDesignKit
import SwiftUI

struct CalendarContent: View {
  let nights: [NightSummary]
  let today: Date
  let onOpen: (NightSummary) -> Void
  @State private var month: Date?
  @State private var selected: Date?
  @Environment(\.theme) private var theme
  private let calendar = Calendar.current

  var body: some View {
    let shown = month ?? today
    let selectedDay = selected ?? calendar.startOfDay(for: today)
    let stats = CalendarMonth(month: shown, nights: nights)
    VStack(spacing: 16) {
      MonthHeader(
        title: shown.formatted(.dateTime.month(.wide).year()),
        onPrevious: { month = calendar.date(byAdding: .month, value: -1, to: shown) },
        onNext: { month = calendar.date(byAdding: .month, value: 1, to: shown) },
        onToday: {
          month = today
          selected = calendar.startOfDay(for: today)
        })

      CalendarMonthGrid(days: CalendarMonth.grid(for: shown).map { date in
        CalendarMonthGrid.Day(
          date: date,
          isInMonth: calendar.isDate(date, equalTo: shown, toGranularity: .month),
          isSelected: calendar.isDate(date, inSameDayAs: selectedDay),
          loudest: CalendarMonth.night(on: date, in: nights)?.loudestIntensity)
      }) { selected = $0 }

      HStack(spacing: 8) {
        CenteredStatTile(icon: "moon.fill", label: Strings.sessionsCalendarStatCardLabel, value: "\(stats.nights.count)")
        CenteredStatTile(icon: "scope", label: Strings.avgScoreCalendarStatCardLabel, value: stats.averageScore.map { "\($0)" } ?? "—")
        CenteredStatTile(icon: "speaker.wave.3.fill", label: Strings.loudNightsCalendarStatCardLabel, value: "\(stats.loudNightCount)")
      }

      if let night = CalendarMonth.night(on: selectedDay, in: nights) {
        VStack(alignment: .leading, spacing: 8) {
          Text(Strings.statsCalendarSelectedNightLabel)
            .font(theme.typography.font(size: 11, weight: .semibold))
            .foregroundStyle(theme.palette.textTertiary)
            .tracking(1)
          NightCard(
            score: night.score,
            title: selectedDay.formatted(.dateTime.weekday(.wide).month(.wide).day()),
            detail: "\(Self.loudnessLabel(night.loudestIntensity)) · \(String(format: Strings.a11yScoreOutOf100, night.score))")
          { onOpen(night) }
        }
      }

      SnoringLegend()
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 20)
  }

  /// The night's loudest snoring, in words.
  static func loudnessLabel(_ intensity: SnoreIntensity?) -> String {
    switch intensity {
    case .epic: Strings.statsCalendarLegendEpic
    case .loud: Strings.statsCalendarLegendLoud
    case .light: Strings.statsCalendarLegendLight
    case .quiet: Strings.statsCalendarIntensityQuiet
    case nil: Strings.quietIntensityLabel
    }
  }
}
