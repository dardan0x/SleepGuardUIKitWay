import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

/// Every recorded night in a UIKit list whose cells are the shared day cards.
/// Draws `HistoryViewModel`'s state and alerts; the view model decides.
public final class HistoryViewController: ScreenController {
  let viewModel: HistoryViewModel
  private var observing: Task<Void, Never>?
  private(set) var deleting: Task<Void, Never>?
  private lazy var loading = host(NightsListLoadingContent())
  private lazy var empty = host(NightsListEmptyContent())
  private lazy var list = NightsListController(
    theme: theme,
    onOpen: { [weak self] night in self?.viewModel.open(night) },
    onDelete: { [weak self] day in self?.viewModel.askToDelete(day) })

  public init(viewModel: HistoryViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    observing?.cancel()
    deleting?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    renderTracking { [weak self] in self?.render() }
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

  private func render() {
    switch viewModel.state {
    case .loading: show(loading)
    case .empty: show(empty)
    case let .loaded(months):
      list.show(months, animated: stateChild === list)
      show(list)
    }
    presentAlert(viewModel.alert, make: alert(for:))
  }

  func alert(for due: HistoryViewModel.Alert) -> UIAlertController {
    switch due {
    case let .confirmDelete(day):
      let alert = UIAlertController(
        title: Strings.recordingsDetailRemoveTitle,
        message: String(format: Strings.recordingsDetailRemoveConfirmFormat, day.nights.count),
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: Strings.actionRemove, style: .destructive) { [weak self] _ in
        self?.confirmDelete()
      })
      alert.addAction(UIAlertAction(title: Strings.actionDiscard, style: .cancel) { [weak self] _ in
        self?.viewModel.dismissAlert()
      })
      return alert
    case .deleteFailed:
      let alert = UIAlertController(title: Strings.recordingsErrorTitle, message: nil, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: Strings.actionOk, style: .default) { [weak self] _ in
        self?.viewModel.dismissAlert()
      })
      return alert
    }
  }

  private func confirmDelete() {
    deleting = Task { [viewModel] in await viewModel.confirmDelete() }
  }
}
