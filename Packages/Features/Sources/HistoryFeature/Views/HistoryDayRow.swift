import SleepCore
import SleepGuardDesignKit
import SwiftUI

/// One day: date, duration, events, average score. A day with one night opens
/// it on tap; a day with several expands to list them.
struct HistoryDayRow: View {
  let day: HistoryDay
  let onOpen: (NightSummary) -> Void
  @State private var isExpanded = false
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 0) {
      Button(action: tap) {
        HStack(spacing: 16) {
          VStack(alignment: .leading, spacing: 6) {
            Text(day.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
              .font(theme.typography.font(size: 16, weight: .semibold))
              .foregroundStyle(theme.palette.textPrimary)
            details
          }
          Spacer()
          ScoreBadge(score: day.averageScore, size: 40)
          Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(theme.palette.textTertiary)
            .rotationEffect(.degrees(isExpanded ? 90 : 0))
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      if isExpanded {
        Divider().overlay(theme.palette.textTertiary.opacity(0.2)).padding(.horizontal, 16)
        ForEach(day.nights) { night in
          HistoryNightRow(night: night) { onOpen(night) }
        }
        .padding(.bottom, 4)
      }
    }
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
  }

  private var details: some View {
    HStack(spacing: 6) {
      if day.nights.count > 1 {
        Text(String(format: Strings.sessionsDetailSessionsCountFormat, day.nights.count))
          .font(theme.typography.font(size: 11, weight: .semibold))
          .foregroundStyle(theme.palette.accent)
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(theme.palette.accentDim, in: .capsule)
          .fixedSize()
      }
      Text(Duration.seconds(day.totalDuration).formatted(.units(allowed: [.hours, .minutes], width: .narrow)))
        .fixedSize()
      Text("•").accessibilityHidden(true)
      Text(String(format: Strings.recordingsDetailEventsCountFormat, day.totalEvents))
        .fixedSize()
    }
    .font(theme.typography.font(size: 13))
    .foregroundStyle(theme.palette.textSecondary)
  }

  private func tap() {
    if day.nights.count == 1 {
      onOpen(day.nights[0])
    } else {
      withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
    }
  }
}

/// A night inside an expanded day.
struct HistoryNightRow: View {
  let night: NightSummary
  let onOpen: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    Button(action: onOpen) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text((night.start..<night.end).formatted(.interval.hour().minute()))
            .font(theme.typography.font(size: 14, weight: .medium))
            .foregroundStyle(theme.palette.textPrimary)
          Text(String(format: Strings.recordingsDetailEventsCountFormat, night.eventCount))
            .font(theme.typography.font(size: 12))
            .foregroundStyle(theme.palette.textSecondary)
        }
        Spacer()
        ScoreBadge(score: night.score, size: 32)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

/// The score in a circle of its band's colour.
struct ScoreBadge: View {
  let score: Int
  let size: CGFloat
  @Environment(\.theme) private var theme

  var body: some View {
    Text("\(score)")
      .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
      .foregroundStyle(theme.palette.textPrimary)
      .frame(width: size, height: size)
      .background(theme.scoreColor(score), in: .circle)
  }
}
