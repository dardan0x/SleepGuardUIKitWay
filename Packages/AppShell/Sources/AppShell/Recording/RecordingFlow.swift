import RecordingFeature
import ScreenKit
import SleepCore
import SleepDomain
import UIKit

/// A night, start to finish: prestart → (start delay countdown) → bedside
/// clock → summary → saved or discarded. A full-screen modal owned by `AppCoordinator`, so it works
/// whichever tabs a brand has (SleepGuard's summary only appeared while its
/// Statistics tab was alive). Each step replaces the last: there is no going
/// back to a finished step. A night recovered at launch starts at its summary.
final class RecordingFlow {
  private let navigator: any Navigator
  private let factory: RecordingFactory
  private let commit: CommitSession
  private let discardRecording: DiscardRecording
  private let enforceStorageLimits: EnforceStorageLimits
  private let device: DeviceServices
  private let onClose: @MainActor () -> Void
  /// The screen, the battery and the start delay's warm microphone.
  private let lifecycle: NightLifecycle
  /// The Snore Interrupter's settings sheets, from the prestart.
  let interrupter: InterrupterSettingsNavigation
  /// The night in progress, kept here for the whole night.
  private(set) var model: LiveRecordingModel?
  /// Saving, discarding or a low-battery stop, awaited by tests.
  private(set) var finishing: Task<Void, Never>?
  /// The storage limits after a save, awaited by tests.
  private(set) var cleanup: Task<Void, Never>?

  init(
    navigator: any Navigator,
    factory: RecordingFactory,
    commit: CommitSession,
    discardRecording: DiscardRecording,
    enforceStorageLimits: EnforceStorageLimits,
    device: DeviceServices,
    preferences: any PreferencesStore,
    onClose: @escaping @MainActor () -> Void)
  {
    self.navigator = navigator
    self.factory = factory
    self.commit = commit
    self.discardRecording = discardRecording
    self.enforceStorageLimits = enforceStorageLimits
    self.device = device
    self.onClose = onClose
    lifecycle = NightLifecycle(device: device)
    interrupter = InterrupterSettingsNavigation(navigator: navigator, factory: factory, preferences: preferences)
  }

  func start() {
    navigator.setRoot(factory.makePrestart(routes: RecordingPrestartRoutes(
      start: { [weak self] preferences in self?.begin(preferences) },
      cancel: { [weak self] in self?.onClose() },
      openSettings: device.openSettings,
      openInterrupter: { [weak self] saved in self?.interrupter.open(saved: saved) })))
  }

  /// A night the app didn't get to finish, offered at launch: its summary.
  func start(recovering night: Night) {
    showSummary(night)
  }

  /// Stops the night before the battery runs out, when it is that low.
  /// Called on a timer while recording; internal for tests.
  func checkBattery() {
    guard let model, model.phase == .recording, finishing == nil, let level = lifecycle.lowBatteryLevelNow else { return }
    Log.app.notice("Battery at \(Int(level * 100))%: stopping and keeping the night")
    finishing = Task {
      let night = await model.stop(endReason: .lowBattery)
      finishing = nil
      showSummary(night)
    }
  }

  // MARK: - Steps

  /// Now, or after the start delay.
  private func begin(_ preferences: AppPreferences) {
    let minutes = RecordingDelay.valid(preferences.recordingDelayMinutes)
    guard minutes > 0 else { return startNight(capture: factory.makeCapture(), preferences: preferences) }
    let target = Date().addingTimeInterval(TimeInterval(minutes * 60))
    lifecycle.beginDelay(capture: factory.makeCapture(), until: target)
    navigator.setRoot(factory.makeCountdown(target: target, routes: RecordingCountdownRoutes(
      cancel: { [weak self] in
        self?.lifecycle.cancelDelay()
        self?.start()
      },
      start: { [weak self] in
        guard let self, let capture = lifecycle.endDelay() else { return }
        startNight(capture: capture, preferences: preferences)
      })))
  }

  private func startNight(capture: any AudioCapture, preferences: AppPreferences) {
    let model = factory.makeModel(capture: capture, preferences: preferences)
    self.model = model
    lifecycle.nightStarted { [weak self] in self?.checkBattery() }
    navigator.setRoot(factory.makeBedside(model: model, routes: BedsideClockRoutes(
      finished: { [weak self] night in self?.showSummary(night) },
      discarded: { [weak self] night in self?.discard(night) })))
  }

  private func showSummary(_ night: Night) {
    endNight()
    navigator.setRoot(factory.makeSummary(night: night, routes: SessionSummaryRoutes(
      save: { [weak self] night in self?.save(night) },
      discard: { [weak self] night in self?.discard(night) })))
  }

  /// Commits and closes; on failure says so and stays on the summary, where
  /// Save can be tried again.
  private func save(_ night: Night) {
    guard finishing == nil else { return }
    finishing = Task { [commit, factory] in
      do {
        try await commit(night)
        enforceLimits()
        onClose()
      } catch {
        Log.storage.error("Saving the night failed: \(error.localizedDescription, privacy: .public)")
        finishing = nil
        navigator.present(factory.makeSaveFailedAlert(), style: .alert)
      }
    }
  }

  /// The storage limits, now that a night was added (SleepGuard runs them
  /// after each save). A failure is logged; the night is saved.
  private func enforceLimits() {
    cleanup = Task { [enforceStorageLimits] in
      do {
        try await enforceStorageLimits()
      } catch {
        Log.storage.error("Storage limits failed: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  /// Removes the night's clips and its checkpoint, then closes.
  private func discard(_ night: Night?) {
    endNight()
    finishing = Task { [discardRecording] in
      await discardRecording(night)
      onClose()
    }
  }

  private func endNight() {
    lifecycle.nightEnded()
    model = nil
  }
}
