import SleepCore
import SleepGuardDesignKit
import SwiftUI

/// Every event under the detail's current filter, as a grid of cards. The
/// title and the close button belong to the sheet's navigation bar (shell).
public struct EventsSheetScreen: View {
  let rows: [DetailEventRow]
  let events: [NightEvent]
  let playEvents: @MainActor ([NightEvent], NightEvent.ID) -> Void

  public init(rows: [DetailEventRow], events: [NightEvent], playEvents: @escaping @MainActor ([NightEvent], NightEvent.ID) -> Void) {
    self.rows = rows
    self.events = events
    self.playEvents = playEvents
  }

  public var body: some View {
    ScrollView(showsIndicators: false) {
      EventCardGrid(rows: rows) { playEvents($0.playback(in: events), $0.id) }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
  }
}

/// Three cards per line.
struct EventCardGrid: View {
  let rows: [DetailEventRow]
  let onPlay: (DetailEventRow) -> Void

  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
      ForEach(rows) { row in
        EventCard(start: row.start, duration: row.duration, category: row.category, intensity: row.intensity) { onPlay(row) }
      }
    }
  }
}
