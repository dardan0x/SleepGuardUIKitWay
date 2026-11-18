import ScreenKit
import SleepCore
import SleepGuardContentKit
import SwiftUI
import UIKit

/// Trends: the last week's or month's nights, each on its own, in the shared
/// `TrendsContent`; the numbers are SleepCore's `NightPeriod`, the title is in
/// the navigation bar. Owns the range.
public final class TrendsViewController: NightsScreenController {
  private(set) var range = TrendsRange.week

  override public init(dependencies: StatisticsDependencies, theme: Theme, chrome: ScreenChrome) {
    super.init(dependencies: dependencies, theme: theme, chrome: chrome)
  }

  override func render() {
    guard let nights else { return }
    let period = NightPeriod(lastDays: range.days, of: nights, now: Date())
    let range = Binding(get: { [weak self] in self?.range ?? .week }, set: { [weak self] in self?.select($0) })
    list.rows = [.init(id: "trends", configuration: hosted { TrendsContent(range: range, period: period) })]
  }

  func select(_ range: TrendsRange) {
    self.range = range
    render()
  }
}
