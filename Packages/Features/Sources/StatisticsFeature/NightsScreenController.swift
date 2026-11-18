import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import UIKit

/// For routes of screens that list nights (Last 7 Nights, Calendar).
public struct NightListRoutes {
  /// A day's first night.
  public var openNight: @MainActor (NightSummary) -> Void

  public init(openNight: @escaping @MainActor (NightSummary) -> Void) {
    self.openNight = openNight
  }
}

/// The base of a statistics screen over every night (Trends, Calendar, Last 7
/// Nights): the placeholder until the first list, then the screen's content
/// in a UIKit list, redrawn live from the repository while it is on screen.
/// No empty state: the numbers read 0.
public class NightsScreenController: ScreenController {
  let dependencies: StatisticsDependencies
  let list = ContentListController()
  /// Every night, once loaded.
  private(set) var nights: [NightSummary]?
  private var observing: Task<Void, Never>?

  init(dependencies: StatisticsDependencies, theme: Theme, chrome: ScreenChrome) {
    self.dependencies = dependencies
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    observing?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    show(host(StatisticsLoadingContent()))
  }

  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    guard observing == nil else { return }
    let repository = dependencies.nights
    observing = Task { [weak self] in
      for await nights in await repository.observeSummaries() {
        self?.show(nights)
      }
    }
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    observing?.cancel()
    observing = nil
  }

  /// Internal for tests.
  func show(_ nights: [NightSummary]) {
    self.nights = nights
    render()
    show(list)
  }

  /// Redraws `list` from `nights`. Each screen draws its own content.
  func render() {}
}
