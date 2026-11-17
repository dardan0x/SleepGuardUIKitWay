import SleepCore
import SleepGuardContentKit
import SwiftUI

/// Every event under the detail's current filter, as the shared grid of
/// cards. The title and the close button belong to the sheet's navigation bar
/// (shell).
public struct EventsSheetScreen: View {
  let rows: [EventListRow]
  let events: [NightEvent]
  let playEvents: @MainActor ([NightEvent], NightEvent.ID) -> Void

  public init(rows: [EventListRow], events: [NightEvent], playEvents: @escaping @MainActor ([NightEvent], NightEvent.ID) -> Void) {
    self.rows = rows
    self.events = events
    self.playEvents = playEvents
  }

  public var body: some View {
    ScrollView(showsIndicators: false) {
      EventsGridContent(rows: rows) { playEvents($0.playback(in: events), $0.id) }
    }
  }
}
