import FactoryKit
import RecordingFeature
import ScreenKit
import SleepCore
import SleepDomain
import UIKit

/// A night, start to finish: prestart → bedside clock → summary → saved or
/// discarded. A full-screen modal owned by `AppCoordinator`, so it works
/// whichever tabs a brand has (SleepGuard's summary only appeared while its
/// Statistics tab was alive). Each step replaces the last: there is no going
/// back to a finished step.
final class RecordingFlow {
  private let navigator: any Navigator
  private let composer: RecordingComposer
  private let commit: CommitSession
  private let files: any SessionFileStore
  private let device: DeviceServices
  private let onClose: @MainActor () -> Void
  /// The night in progress, kept here for the whole night.
  private(set) var model: LiveRecordingModel?
  /// Saving or discarding, awaited by tests.
  private(set) var finishing: Task<Void, Never>?

  init(navigator: any Navigator, container: Container, compactHeight: Bool, onClose: @escaping @MainActor () -> Void) {
    self.navigator = navigator
    composer = RecordingComposer(container: container, compactHeight: compactHeight)
    commit = container.commitSession()
    files = container.sessionFileStore()
    device = container.deviceServices()
    self.onClose = onClose
  }

  func start() {
    navigator.setRoot(composer.makePrestart(routes: RecordingPrestartRoutes(
      start: { [weak self] in self?.startNight() },
      cancel: { [weak self] in self?.onClose() },
      openSettings: device.openSettings)))
  }

  private func startNight() {
    let model = composer.makeModel()
    self.model = model
    device.keepScreenOn(true)
    navigator.setRoot(composer.makeBedside(model: model, routes: BedsideClockRoutes(
      finished: { [weak self] night in self?.showSummary(night) },
      discarded: { [weak self] night in self?.discard(night) })))
  }

  private func showSummary(_ night: Night) {
    device.keepScreenOn(false)
    model = nil
    navigator.setRoot(composer.makeSummary(night: night, routes: SessionSummaryRoutes(
      save: { [weak self] night in self?.save(night) },
      discard: { [weak self] night in self?.discard(night) })))
  }

  /// Commits and closes; on failure says so and stays on the summary, where
  /// Save can be tried again.
  private func save(_ night: Night) {
    guard finishing == nil else { return }
    finishing = Task { [commit, composer] in
      do {
        try await commit(night)
        onClose()
      } catch {
        Log.storage.error("Saving the night failed: \(error.localizedDescription, privacy: .public)")
        finishing = nil
        navigator.present(composer.makeSaveFailedAlert(), style: .alert)
      }
    }
  }

  /// Removes the night's clips (nothing was saved) and closes.
  private func discard(_ night: Night?) {
    device.keepScreenOn(false)
    model = nil
    guard let night else { return onClose() }
    let clips = night.events.compactMap(\.clipFileName)
    finishing = Task { [files] in
      await files.removeFiles(named: clips)
      onClose()
    }
  }
}
