import FactoryKit
import ScreenKit
import SessionDetailFeature
import SleepCore
import SleepDomain
import SleepGuardDesignKit
import UIKit

/// Opening a night, from any tab: push its detail, present its events and
/// sleep-stages sheets, confirm and delete it, then go back. Owned by the tab's flow.
final class NightDetailNavigation {
  private let navigator: any Navigator
  private let detail: SessionDetailComposer
  private let deleteSession: DeleteSession
  private var deleting: Task<Void, Never>?

  init(navigator: any Navigator, container: Container) {
    self.navigator = navigator
    detail = SessionDetailComposer(container: container)
    deleteSession = container.deleteSession()
  }

  deinit {
    deleting?.cancel()
  }

  func show(_ night: NightSummary) {
    navigator.push(detail.make(
      night: night,
      onDelete: { [weak self] in self?.confirmDeleting(night.id) },
      routes: SessionDetailRoutes(
        showAllEvents: { [weak self] rows, events in self?.showEvents(rows, events) },
        playEvents: { [weak self] events, start in self?.play(events, from: start) },
        showStagesInfo: { [weak self] stages in self?.showStagesInfo(stages) })))
  }

  /// The sleep-stages sheet, from the detail or the dashboard; its own close
  /// button dismisses it.
  func showStagesInfo(_ stages: SleepStageBreakdown) {
    navigator.present(
      detail.makeStagesInfo(stages, onClose: { [weak self] in self?.navigator.dismiss() }),
      style: .sheet(detents: [.large]))
  }

  /// Medium and large detents; the close button dismisses it.
  private func showEvents(_ rows: [EventListRow], _ events: [NightEvent]) {
    navigator.present(
      detail.makeEventsSheet(
        rows: rows, events: events,
        playEvents: { [weak self] events, start in self?.play(events, from: start) },
        onClose: { [weak self] in self?.navigator.dismiss() }),
      style: .sheet(detents: [.medium, .large]))
  }

  /// The player sheet, over whatever is showing (the events sheet stays
  /// under it). SleepGuard's height, and large; closing releases the audio.
  private func play(_ events: [NightEvent], from start: NightEvent.ID) {
    navigator.present(
      detail.makePlayer(events: events, start: start, onClose: { [weak self] in self?.navigator.dismiss() }),
      style: .sheet(detents: [.height(580), .large]))
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

  /// Deletes, then goes back to the screen before (which updates itself). If
  /// the delete fails the detail stays, so the night is still there to retry.
  func delete(_ id: Night.ID) async {
    do {
      try await deleteSession(id)
      navigator.pop()
    } catch {
      Log.storage.error("Deleting a night failed: \(error.localizedDescription, privacy: .public)")
    }
  }
}
