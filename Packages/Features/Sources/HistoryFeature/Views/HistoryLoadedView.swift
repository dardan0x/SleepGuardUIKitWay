import SleepCore
import SleepGuardDesignKit
import SwiftUI

/// Month sections of day rows. Swipe a day to delete it (after confirmation).
struct HistoryLoadedView: View {
  let months: [HistoryMonth]
  let onOpen: (Night.ID) -> Void
  let onDelete: (HistoryDay) -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    List {
      ForEach(months) { month in
        Section {
          ForEach(month.days) { day in
            HistoryDayRow(day: day, onOpen: onOpen)
              .padding(.vertical, 8)
              .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                  onDelete(day)
                } label: {
                  Label(Strings.actionDelete, systemImage: "trash")
                }
              }
              .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
          }
        } header: {
          Text(month.month.formatted(.dateTime.month(.wide).year()))
            .font(theme.typography.font(size: 13, weight: .semibold))
            .foregroundStyle(theme.palette.textTertiary)
            .textCase(.uppercase)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }
}

/// Placeholder rows while the first list loads.
struct HistoryLoadingView: View {
  var body: some View {
    let placeholder = HistoryDay(
      id: .now,
      nights: [NightSummary(id: UUID(), start: .now, end: .now.addingTimeInterval(8 * 3600), score: 80, snoringDuration: 0, eventCount: 3)])
    VStack(spacing: 16) {
      ForEach(0..<4, id: \.self) { _ in
        HistoryDayRow(day: placeholder, onOpen: { _ in })
      }
      Spacer()
    }
    .padding(16)
    .redacted(reason: .placeholder)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

struct HistoryEmptyView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "waveform.slash")
        .font(.system(size: 48))
        .foregroundStyle(theme.palette.textTertiary)
        .accessibilityHidden(true)

      Text(Strings.recordingsEmptyTitle)
        .font(theme.typography.font(size: 20, weight: .semibold))
        .foregroundStyle(theme.palette.textPrimary)

      Text(Strings.recordingsEmptyMessage)
        .font(theme.typography.font(size: 15))
        .foregroundStyle(theme.palette.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
