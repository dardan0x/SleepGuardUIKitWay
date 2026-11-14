import FactoryKit
import HistoryFeature
import ScreenKit
import SessionDetailFeature
import SleepCore
import SleepDomain
import SleepGuardDesignKit
import UIKit

/// The Sessions tab: the list of nights, a night's detail, deleting a night.
/// Screens say what the user asked for; this flow decides what happens.
final class HistoryFlow: TabFlow {
  let tab = AppTab.history
  let navigator: any Navigator
  private let history: HistoryScreenComposer
  private let detail: SessionDetailComposer
  private let deleteSession: DeleteSession
  private var deleting: Task<Void, Never>?

  init(navigator: any Navigator, container: Container) {
    self.navigator = navigator
    history = HistoryScreenComposer(container: container)
    detail = SessionDetailComposer(container: container)
    deleteSession = container.deleteSession()
  }

  deinit {
    deleting?.cancel()
  }

  func start() {
    navigator.setRoot(history.make(routes: HistoryRoutes(
      openNight: { [weak self] night in self?.showDetail(of: night) })))
  }

  private func showDetail(of night: NightSummary) {
    navigator.push(detail.make(
      night: night,
      onDelete: { [weak self] in self?.confirmDeleting(night.id) },
      routes: SessionDetailRoutes(showAllEvents: { [weak self] rows in self?.showEvents(rows) })))
  }

  /// Medium and large detents; the close button dismisses it.
  private func showEvents(_ rows: [DetailEventRow]) {
    navigator.present(
      detail.makeEventsSheet(rows: rows, onClose: { [weak self] in self?.navigator.dismiss() }),
      style: .sheet(detents: [.medium, .large]))
  }

  private func confirmDeleting(_ id: Night.ID) {
    navigator.present(deleteConfirmation(for: id), style: .alert)
  }

  /// "Delete This Night?" with Cancel and a destructive Delete.
  func deleteConfirmation(for id: Night.ID) -> UIAlertController {
    let alert = UIAlertController(
      title: Strings.sessionDeleteConfirmTitle, message: Strings.sessionDeleteConfirmMessage, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionCancel, style: .cancel))
    alert.addAction(UIAlertAction(title: Strings.actionDelete, style: .destructive) { [weak self] _ in
      self?.startDeleting(id)
    })
    return alert
  }

  private func startDeleting(_ id: Night.ID) {
    deleting = Task { [weak self] in await self?.delete(id) }
  }

  /// Deletes, then goes back to the list (which updates itself). If the delete
  /// fails the detail stays, so the night is still there to retry.
  func delete(_ id: Night.ID) async {
    do {
      try await deleteSession(id)
      navigator.pop()
    } catch {
      Log.storage.error("Deleting a night failed: \(error.localizedDescription, privacy: .public)")
    }
  }
}
