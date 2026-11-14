import SleepCore
import SleepGuardDesignKit
import SwiftUI

/// Time, length and kind of one event (or snoring episode). Play and share
/// arrive with clip playback (F5).
struct DetailEventRowView: View {
  let row: DetailEventRow
  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 12) {
      indicator
      Text(row.start.formatted(date: .omitted, time: .shortened))
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundStyle(theme.palette.textPrimary)
        .monospacedDigit()
      Text(Duration.seconds(row.duration).formatted(.time(pattern: .minuteSecond)))
        .font(theme.typography.font(size: 14, weight: .medium))
        .foregroundStyle(theme.palette.textSecondary)
        .monospacedDigit()
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private var indicator: some View {
    switch row.category {
    case .snoring:
      Circle().fill(row.color(in: theme.palette)).frame(width: 10, height: 10).accessibilityHidden(true)
    case .sleepTalking:
      Image(systemName: "bubble.left.fill")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.palette.sleepTalking)
        .frame(width: 12, height: 12)
        .accessibilityHidden(true)
    case .noise, .coughing, .other:
      Image(systemName: "waveform")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(theme.palette.noise)
        .frame(width: 12, height: 12)
        .accessibilityHidden(true)
    }
  }
}

extension DetailEventRow {
  /// Snoring by intensity; sleep talking and noise by their category colour.
  func color(in palette: Palette) -> Color {
    switch category {
    case .snoring:
      switch intensity {
      case .quiet: palette.snoreQuiet
      case .light: palette.snoreLight
      case .loud: palette.snoreLoud
      case .epic: palette.snoreEpic
      }
    case .sleepTalking: palette.sleepTalking
    case .noise, .coughing, .other: palette.noise
    }
  }
}
