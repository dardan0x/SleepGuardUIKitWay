import ScreenKit
import SleepCore
import SleepGuardContentKit
import SleepGuardDesignKit
import UIKit

/// Every event under the detail's current filter, drawn from
/// `EventsSheetViewModel` as the shared grid of cards in a UIKit list. The
/// title and the close button belong to the sheet's navigation bar (shell).
public final class EventsSheetViewController: ScreenController {
  let viewModel: EventsSheetViewModel
  private let list = ContentListController()

  public init(viewModel: EventsSheetViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    show(list)
    list.collectionView.showsVerticalScrollIndicator = false
    let viewModel = viewModel
    list.rows = [.init(id: "grid", configuration: hosted {
      EventsGridContent(rows: viewModel.rows) { viewModel.play($0) }
    })]
  }
}
