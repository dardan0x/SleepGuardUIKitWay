import ScreenKit
import SleepCore
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
/// Nights): the placeholder until `NightsViewModel` has the first list, then
/// the screen's content in a UIKit list, redrawn as the view model changes.
public class NightsScreenController: ScreenController {
  let viewModel: NightsViewModel
  let list = ContentListController()
  private var observing: Task<Void, Never>?
  private lazy var loading = host(StatisticsLoadingContent())

  init(viewModel: NightsViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    observing?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    renderTracking { [weak self] in self?.redraw() }
  }

  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    guard observing == nil else { return }
    observing = Task { [viewModel] in await viewModel.observe() }
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    observing?.cancel()
    observing = nil
  }

  /// Redraws from the view model. Called again by subclasses when a view-only
  /// selection changes.
  func redraw() {
    guard let nights = viewModel.nights else { return show(loading) }
    render(nights)
    show(list)
  }

  /// Draws `list` from `nights`. Each screen draws its own content.
  func render(_: [NightSummary]) {}
}
