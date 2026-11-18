import ScreenKit
import SleepCore
import SleepGuardContentKit
import SwiftUI
import UIKit

/// Trends: the last week's or month's nights, each on its own, in the shared
/// `TrendsContent`; the numbers are SleepCore's `NightPeriod`, the title is in
/// the navigation bar. The range is a view choice the shared content offers,
/// so it lives here.
public final class TrendsViewController: NightsScreenController {
  private(set) var range = TrendsRange.week

  override public init(viewModel: NightsViewModel, theme: Theme, chrome: ScreenChrome) {
    super.init(viewModel: viewModel, theme: theme, chrome: chrome)
  }

  override func render(_ nights: [NightSummary]) {
    let period = NightPeriod(lastDays: range.days, of: nights, now: Date())
    let range = Binding(get: { [weak self] in self?.range ?? .week }, set: { [weak self] in self?.select($0) })
    list.rows = [.init(id: "trends", configuration: hosted { TrendsContent(range: range, period: period) })]
  }

  func select(_ range: TrendsRange) {
    self.range = range
    redraw()
  }
}
