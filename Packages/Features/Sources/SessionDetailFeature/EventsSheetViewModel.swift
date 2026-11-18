import Foundation
import Observation
import SleepCore

public struct EventsSheetRoutes {
  /// Play: the events to play in order, starting with the given one.
  public var playEvents: @MainActor ([NightEvent], NightEvent.ID) -> Void

  public init(playEvents: @escaping @MainActor ([NightEvent], NightEvent.ID) -> Void) {
    self.playEvents = playEvents
  }
}

/// Every event under the detail's current filter; Play plays a row's
/// episode (SleepCore's `EventListRow.playback(in:)`).
@MainActor
@Observable
public final class EventsSheetViewModel {
  public let rows: [EventListRow]
  let events: [NightEvent]
  let routes: EventsSheetRoutes

  public init(rows: [EventListRow], events: [NightEvent], routes: EventsSheetRoutes) {
    self.rows = rows
    self.events = events
    self.routes = routes
  }

  public func play(_ row: EventListRow) {
    routes.playEvents(row.playback(in: events), row.id)
  }
}
