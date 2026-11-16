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
/// back to a finished step. A night recovered at launch starts at its summary.
final class RecordingFlow {
  /// SleepGuard's low-battery line: at or under 2%, the night is stopped and
  /// kept before the phone dies.
  static let lowBatteryLevel: Float = 0.02
  /// How often the battery is checked while recording.
  static let batteryCheckInterval: Duration = .seconds(30)

  private let navigator: any Navigator
  private let composer: RecordingComposer
  private let commit: CommitSession
  private let discardRecording: DiscardRecording
  private let device: DeviceServices
  private let onClose: @MainActor () -> Void
  /// The night in progress, kept here for the whole night.
  private(set) var model: LiveRecordingModel?
  /// Saving, discarding or a low-battery stop, awaited by tests.
  private(set) var finishing: Task<Void, Never>?
  private var batteryWatch: Task<Void, Never>?

  init(navigator: any Navigator, container: Container, compactHeight: Bool, onClose: @escaping @MainActor () -> Void) {
    self.navigator = navigator
    composer = RecordingComposer(container: container, compactHeight: compactHeight)
    commit = container.commitSession()
    discardRecording = container.discardRecording()
    device = container.deviceServices()
    self.onClose = onClose
  }

  deinit {
    batteryWatch?.cancel()
  }

  func start() {
    navigator.setRoot(composer.makePrestart(routes: RecordingPrestartRoutes(
      start: { [weak self] in self?.startNight() },
      cancel: { [weak self] in self?.onClose() },
      openSettings: device.openSettings)))
  }

  /// A night the app didn't get to finish, offered at launch: its summary.
  func start(recovering night: Night) {
    showSummary(night)
  }

  /// Stops the night before the battery runs out, when it is that low.
  /// Called on a timer while recording; internal for tests.
  func checkBattery() {
    guard let model, model.phase == .recording, finishing == nil,
          let level = device.batteryLevel(), level <= Self.lowBatteryLevel else { return }
    Log.app.notice("Battery at \(Int(level * 100))%: stopping and keeping the night")
    finishing = Task {
      let night = await model.stop(endReason: .lowBattery)
      finishing = nil
      showSummary(night)
    }
  }

  private func startNight() {
    let model = composer.makeModel()
    self.model = model
    device.keepScreenOn(true)
    batteryWatch = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: Self.batteryCheckInterval)
        self?.checkBattery()
      }
    }
    navigator.setRoot(composer.makeBedside(model: model, routes: BedsideClockRoutes(
      finished: { [weak self] night in self?.showSummary(night) },
      discarded: { [weak self] night in self?.discard(night) })))
  }

  private func showSummary(_ night: Night) {
    stopWatching()
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

  /// Removes the night's clips and its checkpoint, then closes.
  private func discard(_ night: Night?) {
    stopWatching()
    finishing = Task { [discardRecording] in
      await discardRecording(night)
      onClose()
    }
  }

  /// Recording is over: the screen may sleep, the battery isn't watched.
  private func stopWatching() {
    batteryWatch?.cancel()
    batteryWatch = nil
    if model != nil { device.keepScreenOn(false) }
    model = nil
  }
}
