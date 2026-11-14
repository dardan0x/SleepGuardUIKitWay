import SleepGuardDesignKit
import SwiftUI

/// Every event under the detail's current filter, as a grid of cards. The
/// title and the close button belong to the sheet's navigation bar (shell).
/// Play arrives with clip playback (F5).
public struct EventsSheetScreen: View {
  let rows: [DetailEventRow]

  public init(rows: [DetailEventRow]) {
    self.rows = rows
  }

  public var body: some View {
    ScrollView(showsIndicators: false) {
      EventCardGrid(rows: rows)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
  }
}

/// Three cards per line.
struct EventCardGrid: View {
  let rows: [DetailEventRow]

  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
      ForEach(rows) { row in
        EventCard(start: row.start, duration: row.duration, category: row.category, intensity: row.intensity)
      }
    }
  }
}
