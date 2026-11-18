import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI
import UIKit

/// The dashboard: loads the nights live and shows the shared
/// `StatisticsDashboardContent` (same as SleepGuard's) in a UIKit list, with
/// the profile prompt above it when asked for, the latest night's sleep
/// stages in its slot, and Start Recording pinned below. Every number comes
/// from SleepCore's rules; the title and the calendar button belong to the
/// navigation bar (shell).
public final class StatisticsViewController: ScreenController {
  let dependencies: StatisticsDependencies
  let routes: StatisticsRoutes
  /// `now`: when the dashboard was made, for "last night" and the week strip.
  private(set) var dashboard: (NightDashboard, now: Date)?
  private(set) var asksForProfile = false
  private var stages: (of: NightSummary, breakdown: SleepStageBreakdown?)?
  private var observing: Task<Void, Never>?
  private var asking: Task<Void, Never>?
  private var readingStages: Task<Void, Never>?
  private let list = ContentListController()
  private var empty: UIViewController?
  private var loaded: UIViewController?

  public init(dependencies: StatisticsDependencies, routes: StatisticsRoutes, theme: Theme, chrome: ScreenChrome) {
    self.dependencies = dependencies
    self.routes = routes
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    observing?.cancel()
    asking?.cancel()
    readingStages?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    empty = host(StatisticsEmptyContent(onStartRecording: routes.startRecording))
    let button = host(StartRecordingButton(height: 56, action: routes.startRecording))
    button.sizingOptions = .intrinsicContentSize
    loaded = DashboardLayout.make(list: list, button: button)
    show(host(StatisticsLoadingContent()))
  }

  /// Asks about the profile once per appearance, and observes the nights.
  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    asking = Task { [weak self, dependencies] in
      let asks = await dependencies.asksForProfile()
      guard !Task.isCancelled else { return }
      self?.asksForProfile = asks
      self?.render()
    }
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
    for task in [observing, asking, readingStages] {
      task?.cancel()
    }
    observing = nil
  }

  /// Internal for tests.
  func show(_ nights: [NightSummary]) {
    let now = Date()
    guard let made = NightDashboard.make(from: nights, now: now) else {
      dashboard = nil
      if let empty { show(empty) }
      return
    }
    dashboard = (made, now)
    readStages(of: made.latest)
    render()
    if let loaded { show(loaded) }
  }

  /// The dashboard is built from summaries (no stages), so the latest night
  /// is read again whenever its summary changes (stages added on opening it
  /// change its score). Nothing is shown while reading or without stages.
  private func readStages(of latest: NightSummary) {
    guard stages?.of != latest else { return }
    stages = (latest, nil)
    let repository = dependencies.nights
    readingStages?.cancel()
    readingStages = Task { [weak self] in
      let night = try? await repository.session(id: latest.id)
      guard !Task.isCancelled else { return }
      self?.stages = (latest, night.flatMap { SleepStageBreakdown(segments: $0.sleepStages) })
      self?.render()
    }
  }

  private func render() {
    guard let (dashboard, now) = dashboard else { return }
    var rows: [ContentListController.Row] = []
    if asksForProfile {
      rows.append(.init(id: "profile", configuration: hosted {
        ProfilePromptCard(
          onOpen: { [weak self] in self?.answerProfilePrompt(open: true) },
          onDismiss: { [weak self] in self?.answerProfilePrompt(open: false) })
          .padding(.horizontal, 16)
          .padding(.top, 12)
      }))
    }
    let (routes, breakdown) = (routes, stages?.breakdown)
    rows.append(.init(id: "dashboard", configuration: hosted {
      StatisticsDashboardContent(
        dashboard: dashboard, latest: dashboard.latest, now: now,
        onShowTrends: routes.showTrends, onShowLastSevenNights: routes.showLastSevenNights)
      {
        if let breakdown {
          SleepStagesCard(breakdown: breakdown, start: dashboard.latest.start, duration: dashboard.latest.duration) {
            routes.showStagesInfo(breakdown)
          }
        }
      }
    }))
    list.rows = rows
  }

  private func answerProfilePrompt(open: Bool) {
    asksForProfile = false
    render()
    if open { routes.openProfile() } else { routes.dismissProfilePrompt() }
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
