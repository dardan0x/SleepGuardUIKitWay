import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import UIKit

/// One night, drawn from `SessionDetailViewModel`: a UIKit layout of the
/// shared detail pieces (`NightDetailController`), or UIKit placeholders
/// while loading and on error. The title and the delete button belong to
/// the navigation bar, owned by the shell.
public final class SessionDetailViewController: ScreenController {
  let viewModel: SessionDetailViewModel
  private var loadingTask: Task<Void, Never>?
  /// The loaded night's layout, once there is one.
  private(set) var loaded: NightDetailController?
  private lazy var loadingView = Self.controller(SessionDetailLoadingView(theme: theme))
  private lazy var errorView = Self.controller(SessionDetailErrorView(theme: theme) { [weak self] in self?.retry() })

  public init(viewModel: SessionDetailViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    loadingTask?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    renderTracking { [weak self] in self?.render() }
  }

  /// Loads once: coming back from a sheet or a pushed screen keeps the night.
  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    load()
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    loadingTask?.cancel()
    loadingTask = nil
  }

  private func load() {
    guard viewModel.needsLoading, loadingTask == nil else { return }
    loadingTask = Task { [weak self, viewModel] in
      await viewModel.load()
      if !Task.isCancelled { self?.loadingTask = nil }
    }
  }

  private func retry() {
    viewModel.retry()
    load()
  }

  private func render() {
    switch viewModel.state {
    case .loading: show(loadingView)
    case .error: show(errorView)
    case let .loaded(detail):
      let controller = loaded ?? makeLoaded(detail)
      controller.show(filter: viewModel.filter)
      show(controller)
    }
  }

  private func makeLoaded(_ detail: SessionDetail) -> NightDetailController {
    let viewModel = viewModel
    let controller = NightDetailController(detail: detail, theme: theme, actions: .init(
      play: { viewModel.play($0) },
      showAll: { viewModel.showAll($0) },
      share: { viewModel.share($0) },
      stagesInfo: { viewModel.showStagesInfo($0) },
      select: { viewModel.select($0) }))
    loaded = controller
    return controller
  }

  private static func controller(_ view: UIView) -> UIViewController {
    let controller = UIViewController()
    controller.view = view
    return controller
  }
}
