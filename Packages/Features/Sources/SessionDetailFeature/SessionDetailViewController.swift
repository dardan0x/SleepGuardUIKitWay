import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import UIKit

/// One night: loads it and shows it in `NightDetailController`, a UIKit
/// layout of the shared detail pieces (score, stats, sleep stages when there
/// are any, timeline, events with a filter; SleepCore's `EventFilter` and
/// `EventListRow`). The title and the delete button belong to the navigation
/// bar, owned by the shell.
public final class SessionDetailViewController: ScreenController {
  let dependencies: SessionDetailDependencies
  let routes: SessionDetailRoutes
  private var loadingTask: Task<Void, Never>?
  /// The loaded night's layout, once there is one.
  private(set) var loaded: NightDetailController?
  private lazy var loadingView = Self.controller(SessionDetailLoadingView(theme: theme))
  private lazy var errorView = Self.controller(SessionDetailErrorView(theme: theme) { [weak self] in self?.retry() })

  public init(dependencies: SessionDetailDependencies, routes: SessionDetailRoutes, theme: Theme, chrome: ScreenChrome) {
    self.dependencies = dependencies
    self.routes = routes
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    loadingTask?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    show(loadingView)
  }

  /// Loads once: coming back from a sheet or a pushed screen keeps the night.
  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    if loaded == nil, stateChild !== errorView { load() }
  }

  private func load() {
    guard loadingTask == nil else { return }
    let loadDetail = dependencies.loadDetail
    let id = dependencies.nightID
    loadingTask = Task { [weak self] in
      let detail = try? await loadDetail(id)
      // Cancelled on disappearing: the next appearance loads again.
      guard !Task.isCancelled, let self else { return }
      loadingTask = nil
      if let detail { show(detail) } else { show(errorView) }
    }
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    loadingTask?.cancel()
    loadingTask = nil
  }

  /// Internal for tests.
  func show(_ detail: SessionDetail) {
    let night = detail.session
    let controller = NightDetailController(detail: detail, theme: theme, actions: .init(
      play: { [weak self] row in self?.routes.playEvents(row.playback(in: night.events), row.id) },
      showAll: { [weak self] rows in self?.routes.showAllEvents(rows, night.events) },
      share: { [weak self] row in
        if let event = night.events.first(where: { $0.id == row.id }), event.clipFileName != nil {
          self?.routes.shareEvent(event)
        }
      },
      stagesInfo: { [weak self] stages in self?.routes.showStagesInfo(stages) }))
    loaded = controller
    show(controller)
  }

  private static func controller(_ view: UIView) -> UIViewController {
    let controller = UIViewController()
    controller.view = view
    return controller
  }

  private func retry() {
    show(loadingView)
    load()
  }
}
