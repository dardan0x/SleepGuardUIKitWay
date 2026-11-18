import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

/// Every event under the detail's current filter, as the shared grid of
/// cards in a UIKit list. The title and the close button belong to the
/// sheet's navigation bar (shell).
public final class EventsSheetViewController: ScreenController {
  let rows: [EventListRow]
  let events: [NightEvent]
  let playEvents: @MainActor ([NightEvent], NightEvent.ID) -> Void
  private let list = ContentListController()

  public init(
    rows: [EventListRow], events: [NightEvent], playEvents: @escaping @MainActor ([NightEvent], NightEvent.ID) -> Void,
    theme: Theme, chrome: ScreenChrome)
  {
    self.rows = rows
    self.events = events
    self.playEvents = playEvents
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    show(list)
    list.collectionView.showsVerticalScrollIndicator = false
    let (rows, events, play) = (rows, events, playEvents)
    list.rows = [.init(id: "grid", configuration: hosted {
      EventsGridContent(rows: rows) { play($0.playback(in: events), $0.id) }
    })]
  }
}
