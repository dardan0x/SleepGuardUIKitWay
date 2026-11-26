import ScreenKit
import SessionDetailFeature
import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SleepLogging
import UIKit

/// Opening a night, from any tab: push its detail, present its events and
/// sleep-stages sheets, confirm and delete it, then go back. Owned by the tab's flow.
final class NightDetailNavigation {
  private let navigator: any Navigator
  private let detail: SessionDetailFactory
  private let deleteSession: DeleteSession
  private let nights: any SessionRepository
  private let clipsDirectory: URL
  private var deleting: Task<Void, Never>?
  /// Writing a report to share; awaited by tests.
  private(set) var sharing: Task<Void, Never>?

  init(
    navigator: any Navigator,
    detail: SessionDetailFactory,
    deleteSession: DeleteSession,
    nights: any SessionRepository,
    clipsDirectory: URL)
  {
    self.navigator = navigator
    self.detail = detail
    self.deleteSession = deleteSession
    self.nights = nights
    self.clipsDirectory = clipsDirectory
  }

  deinit {
    deleting?.cancel()
  }

  func show(_ night: NightSummary) {
    let report = BarItemActivity(label: Strings.a11yGeneratingReport)
    navigator.push(detail.make(
      night: night,
      report: report,
      onReport: { [weak self] in self?.shareReport(night.id, activity: report) },
      onDelete: { [weak self] in self?.confirmDeleting(night.id) },
      routes: SessionDetailRoutes(
        showAllEvents: { [weak self] rows, events in self?.showEvents(rows, events) },
        playEvents: { [weak self] events, start in self?.play(events, from: start) },
        showStagesInfo: { [weak self] stages in self?.showStagesInfo(stages) },
        shareEvent: { [weak self] event in self?.shareClip(of: event) })))
  }

  // MARK: - Sharing

  /// The night's PDF report, in the share sheet. While it is made the
  /// report button shows so (`activity`); a failure says so.
  func shareReport(_ id: Night.ID, activity: BarItemActivity? = nil) {
    guard sharing == nil else { return }
    activity?.isRunning = true
    sharing = Task { [weak self, nights, detail] in
      defer {
        activity?.isRunning = false
        self?.sharing = nil
      }
      do {
        let night = try await nights.session(id: id)
        let url = try NightReportExport.write(night, appName: Self.appName, to: FileManager.default.temporaryDirectory)
        self?.share(url)
      } catch {
        Log.storage.error("Report not made: \(error.localizedDescription, privacy: .public)")
        self?.navigator.present(detail.makeReportFailedAlert(), style: .alert)
      }
    }
  }

  /// One event's clip, when it has one on disk.
  func shareClip(of event: NightEvent) {
    guard let name = event.clipFileName else { return }
    let url = clipsDirectory.appendingPathComponent(name)
    guard FileManager.default.fileExists(atPath: url.path) else { return }
    share(url)
  }

  private func share(_ url: URL) {
    navigator.present(ShareSheet.make(url), style: .sheet(detents: [.medium, .large]))
  }

  /// The report's title and footer name the app (the brand's display name).
  static var appName: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
      ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "SleepGuard"
  }

  /// The sleep-stages sheet, from the detail or the dashboard; its own close
  /// button dismisses it.
  func showStagesInfo(_ stages: SleepStageBreakdown) {
    navigator.present(style: .sheet(detents: [.large])) { [detail] close in
      detail.makeStagesInfo(stages, onClose: close)
    }
  }

  /// Medium and large detents; the close button dismisses it.
  private func showEvents(_ rows: [EventListRow], _ events: [NightEvent]) {
    navigator.present(style: .sheet(detents: [.medium, .large])) { [detail] close in
      detail.makeEventsSheet(
        rows: rows, events: events,
        playEvents: { [weak self] events, start in self?.play(events, from: start) },
        onClose: close)
    }
  }

  /// The player sheet, over whatever is showing (the events sheet stays
  /// under it). SleepGuard's height, and large; closing releases the audio.
  private func play(_ events: [NightEvent], from start: NightEvent.ID) {
    navigator.present(style: .sheet(detents: [.height(580), .large])) { [detail] close in
      detail.makePlayer(events: events, start: start, onClose: close)
    }
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
