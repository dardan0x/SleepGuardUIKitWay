import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import UIKit

/// Every recorded night, by month and day (SleepCore's `NightMonth`), in a
/// UIKit list whose cells are the shared day cards. Updates live as nights
/// are saved or deleted; re-subscribing when the screen reappears yields the
/// current list at once, so returning from a night never shows the loading
/// state. Confirms and performs deletes.
public final class HistoryViewController: ScreenController {
  let dependencies: HistoryDependencies
  let routes: HistoryRoutes
  private var observing: Task<Void, Never>?
  private(set) var deleting: Task<Void, Never>?
  private lazy var loading = host(NightsListLoadingContent())
  private lazy var empty = host(NightsListEmptyContent())
  private lazy var list = NightsListController(
    theme: theme,
    onOpen: { [weak self] night in self?.routes.openNight(night) },
    onDelete: { [weak self] day in self?.confirmDeleting(day) })

  public init(dependencies: HistoryDependencies, routes: HistoryRoutes, theme: Theme, chrome: ScreenChrome) {
    self.dependencies = dependencies
    self.routes = routes
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    observing?.cancel()
    deleting?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    show(loading)
  }

  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    guard observing == nil else { return }
    let nights = dependencies.nights
    observing = Task { [weak self] in
      for await summaries in await nights.observeSummaries() {
        self?.show(summaries)
      }
    }
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    observing?.cancel()
    observing = nil
  }

  /// Internal for tests.
  func show(_ summaries: [NightSummary]) {
    guard !summaries.isEmpty else { return show(empty) }
    let wasShowing = stateChild === list
    list.show(NightMonth.months(from: summaries, calendar: .autoupdatingCurrent), animated: wasShowing)
    show(list)
  }

  /// "Remove …?" with Remove and Discard, as the SwiftUI screen asked.
  func deleteConfirmation(for day: NightDay) -> UIAlertController {
    let alert = UIAlertController(
      title: Strings.recordingsDetailRemoveTitle,
      message: String(format: Strings.recordingsDetailRemoveConfirmFormat, day.nights.count),
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionRemove, style: .destructive) { [weak self] _ in
      self?.delete(day)
    })
    alert.addAction(UIAlertAction(title: Strings.actionDiscard, style: .cancel))
    return alert
  }

  private func confirmDeleting(_ day: NightDay) {
    present(deleteConfirmation(for: day), animated: true)
  }

  /// The list updates itself from the repository once each night is gone.
  func delete(_ day: NightDay) {
    let deleteNight = dependencies.deleteNight
    deleting = Task { [weak self] in
      do {
        for night in day.nights {
          try await deleteNight(night.id)
        }
      } catch {
        guard !Task.isCancelled, let self else { return }
        let alert = UIAlertController(title: Strings.recordingsErrorTitle, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.actionOk, style: .default))
        present(alert, animated: true)
      }
    }
  }
}
