import ScreenKit
import SleepCore
import SleepGuardContentKit
import SwiftUI
import UIKit

/// The dashboard, drawn from `StatisticsViewModel`: the shared
/// `StatisticsDashboardContent` (same as SleepGuard's) in a UIKit list, with
/// the profile prompt above it when asked for, the latest night's sleep
/// stages in its slot, and Start Recording pinned below. The title and the
/// calendar button belong to the navigation bar (shell).
public final class StatisticsViewController: ScreenController {
  let viewModel: StatisticsViewModel
  private var observing: Task<Void, Never>?
  private var asking: Task<Void, Never>?
  private let list = ContentListController()
  private var loading: UIViewController?
  private var empty: UIViewController?
  private var loaded: UIViewController?

  public init(viewModel: StatisticsViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    observing?.cancel()
    asking?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    let viewModel = viewModel
    loading = host(StatisticsLoadingContent())
    empty = host(StatisticsEmptyContent(onStartRecording: { viewModel.startRecording() }))
    let button = host(StartRecordingButton(height: 56, action: { viewModel.startRecording() }))
    button.sizingOptions = .intrinsicContentSize
    loaded = DashboardLayout.make(list: list, button: button)
    renderTracking { [weak self] in self?.render() }
  }

  /// Asks about the profile once per appearance, and follows the nights.
  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    asking = Task { [viewModel] in await viewModel.checkProfilePrompt() }
    guard observing == nil else { return }
    observing = Task { [viewModel] in await viewModel.observe() }
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    observing?.cancel()
    asking?.cancel()
    observing = nil
  }

  private func render() {
    let child: UIViewController?
    switch viewModel.state {
    case .loading: child = loading
    case .empty: child = empty
    case let .loaded(dashboard, now):
      list.rows = rows(dashboard, now: now)
      child = loaded
    }
    if let child { show(child) }
  }

  private func rows(_ dashboard: NightDashboard, now: Date) -> [ContentListController.Row] {
    let viewModel = viewModel
    var rows: [ContentListController.Row] = []
    if viewModel.asksForProfile {
      rows.append(.init(id: "profile", configuration: hosted {
        ProfilePromptCard(
          onOpen: { viewModel.answerProfilePrompt(open: true) },
          onDismiss: { viewModel.answerProfilePrompt(open: false) })
          .padding(.horizontal, 16)
          .padding(.top, 12)
      }))
    }
    let stages = viewModel.latestStages
    rows.append(.init(id: "dashboard", configuration: hosted {
      StatisticsDashboardContent(
        dashboard: dashboard, latest: dashboard.latest, now: now,
        onShowTrends: { viewModel.showTrends() }, onShowLastSevenNights: { viewModel.showLastSevenNights() })
      {
        if let stages {
          SleepStagesCard(breakdown: stages, start: dashboard.latest.start, duration: dashboard.latest.duration) {
            viewModel.showStagesInfo(stages)
          }
        }
      }
    }))
    return rows
  }
}

/// The loaded dashboard: the list filling the screen, Start Recording below it.
enum DashboardLayout {
  static func make(list: UIViewController, button: UIViewController) -> UIViewController {
    let container = UIViewController()
    for child in [list, button] {
      container.addChild(child)
      child.view.translatesAutoresizingMaskIntoConstraints = false
      child.view.backgroundColor = .clear
      container.view.addSubview(child.view)
      child.didMove(toParent: container)
    }
    let view: UIView = container.view
    NSLayoutConstraint.activate([
      list.view.topAnchor.constraint(equalTo: view.topAnchor),
      list.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      list.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      button.view.topAnchor.constraint(equalTo: list.view.bottomAnchor),
      button.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      button.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      button.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])
    return container
  }
}
