import SleepGuardDesignKit
import SwiftUI

/// One event in the events sheet: start time, and its length in the event's colour.
struct EventCardView: View {
  let row: DetailEventRow
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 2) {
        Text(Strings.startTimeEventCard)
        Text(row.start.formatted(date: .omitted, time: .shortened))
      }
      .font(theme.typography.font(size: 11, weight: .semibold))
      .foregroundStyle(theme.palette.textSecondary)
      .lineLimit(1)
      .minimumScaleFactor(0.7)

      Spacer()

      HStack(spacing: 6) {
        Circle().fill(row.color(in: theme.palette)).frame(width: 8, height: 8).accessibilityHidden(true)
        Text(Duration.seconds(row.duration).formatted(.time(pattern: .minuteSecond)))
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .foregroundStyle(row.color(in: theme.palette))
          .monospacedDigit()
      }

      Spacer()
    }
    .padding(12)
    .frame(maxWidth: .infinity)
    .frame(height: 120)
    .background(theme.palette.bgCard, in: .rect(cornerRadius: theme.radii.card))
    .accessibilityElement(children: .combine)
  }
}
