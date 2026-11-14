import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SwiftUI

struct SessionDetailLoadedView: View {
  let detail: SessionDetail
  let onShowAll: () -> Void

  var body: some View {
    ScrollView {
      SessionDetailContent(detail: detail, onShowAll: onShowAll)
    }
  }
}

/// The scrolling content, separate so it can be rendered in tests.
struct SessionDetailContent: View {
  let detail: SessionDetail
  let onShowAll: () -> Void
  @State private var filter: EventFilter = .all
  @Environment(\.theme) private var theme

  private static let visibleRows = 4

  var body: some View {
    let filters = EventFilter.available(for: detail.session.events)
    let rows = DetailEventRow.make(episodes: detail.episodes, events: detail.session.events, filter: filter)

    VStack(spacing: 24) {
      SessionDetailHeader(detail: detail)

      if !filters.isEmpty {
        Picker(Strings.filterAll, selection: $filter) {
          ForEach(filters, id: \.self) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
      }

      VStack(alignment: .leading, spacing: 16) {
        Text(String(format: filter.listTitle, rows.count))
          .font(theme.typography.font(size: 12, weight: .semibold))
          .foregroundStyle(theme.palette.textTertiary)
          .tracking(1)

        VStack(spacing: 8) {
          ForEach(rows.prefix(Self.visibleRows)) { DetailEventRowView(row: $0) }
        }

        if rows.count > Self.visibleRows {
          Button(String(format: Strings.recordingsDetailShowAllFormat, rows.count), action: onShowAll)
            .font(theme.typography.font(size: 15, weight: .medium))
            .foregroundStyle(theme.palette.accent)
            .frame(maxWidth: .infinity)
        }
      }
    }
    .padding(20)
  }
}

extension EventFilter {
  var title: String {
    switch self {
    case .all: Strings.filterAll
    case .snoring: Strings.filterSnoring
    case .sleepTalking: Strings.filterSleepTalking
    case .noise: Strings.filterNoise
    }
  }

  /// A format with one count, e.g. "SNORING EVENTS · %lld".
  var listTitle: String {
    switch self {
    case .all: Strings.sessionRecordingEventsFormatAll
    case .snoring: Strings.sessionRecordingEventsFormatSnoring
    case .sleepTalking: Strings.sessionRecordingEventsFormatSleepTalking
    case .noise: Strings.sessionRecordingEventsFormatNoise
    }
  }
}
