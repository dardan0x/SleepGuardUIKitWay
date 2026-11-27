import ScreenKit
import SleepCore
import SleepGuardContentKit
import SleepGuardDesignKit
import SwiftUI
import UIKit

/// A month of nights in the shared `CalendarContent` (SleepCore's
/// `CalendarMonth`); the month and the selected day are the view model's.
public final class CalendarViewController: NightsScreenController {
  override public init(viewModel: NightsViewModel, theme: Theme, chrome: ScreenChrome) {
    super.init(viewModel: viewModel, theme: theme, chrome: chrome)
  }

  override func render(_ nights: [NightSummary]) {
    let viewModel = viewModel
    // Read here, not in the bindings, so a change redraws (render tracking).
    let (shownMonth, shownDay) = (viewModel.month, viewModel.selectedDay)
    let month = Binding(get: { shownMonth }, set: { viewModel.setMonth($0) })
    let day = Binding(get: { shownDay }, set: { viewModel.select($0) })
    list.rows = [.init(id: "calendar", configuration: hosted {
      CalendarContent(
        month: month, selectedDay: day, nights: nights, onToday: { viewModel.goToToday() },
        onOpen: { viewModel.open($0) })
    })]
  }
}
