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
  /// SleepGuard's low-battery line: at or under 2%, the night is stopped and
  /// kept before the phone dies.
  static let lowBatteryLevel: Float = 0.02
  /// How often the battery is checked while recording.
  static let batteryCheckInterval: Duration = .seconds(30)

  private let navigator: any Navigator
  private let factory: RecordingFactory
  private let commit: CommitSession
  private let discardRecording: DiscardRecording
  private let enforceStorageLimits: EnforceStorageLimits
  private let device: DeviceServices
  private let onClose: @MainActor () -> Void
  /// The night in progress, kept here for the whole night.
  private(set) var model: LiveRecordingModel?
  /// Saving, discarding or a low-battery stop, awaited by tests.
  private(set) var finishing: Task<Void, Never>?
  private var batteryWatch: Task<Void, Never>?
  /// The capture kept warm during the start delay.
  private var warmCapture: (any AudioCapture)?
  /// The storage limits after a save, awaited by tests.
  private(set) var cleanup: Task<Void, Never>?
  /// Opening the interrupter's settings, then saving them; awaited by tests.
  private(set) var interrupterTask: Task<Void, Never>?
  private let preferences: any PreferencesStore

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
    self.preferences = preferences
    self.onClose = onClose
  }

  deinit {
    batteryWatch?.cancel()
  }

  func start() {
    navigator.setRoot(factory.makePrestart(routes: RecordingPrestartRoutes(
      start: { [weak self] preferences in self?.begin(preferences) },
      cancel: { [weak self] in self?.onClose() },
      openSettings: device.openSettings,
      openInterrupter: { [weak self] saved in self?.openInterrupter(saved: saved) })))
  }

  // MARK: - Snore Interrupter

  /// Its settings as a sheet over the prestart; Save keeps the choice and
  /// hands it back to the prestart's row.
  private func openInterrupter(saved: @escaping @MainActor (SnoreInterrupterChoice) -> Void) {
    guard let store = factory.melodyStore else { return }
    interrupterTask = Task { [preferences] in
      let stored = await preferences.load()
      let choice = SnoreInterrupterChoice(mode: stored.interrupterMode, melodyID: stored.melodyID)
      navigator.present(style: .sheet(detents: [.large])) { [factory] close in
        factory.makeInterrupterSettings(choice: choice, store: store, routes: SnoreInterrupterRoutes(
          chooseSound: { [weak self] current, picked in self?.chooseSound(current: current, store: store, picked: picked) },
          save: { [weak self] choice in
            close()
            saved(choice)
            self?.keep(choice)
          },
          cancel: close))
      }
    }
  }

  private func keep(_ choice: SnoreInterrupterChoice) {
    interrupterTask = Task { [preferences] in
      var stored = await preferences.load()
      stored.interrupterMode = choice.mode
      stored.melodyID = choice.melodyID
      await preferences.save(stored)
    }
  }

  private func chooseSound(current: Int, store: any MelodyStore, picked: @escaping @MainActor (Int) -> Void) {
    navigator.present(style: .sheet(detents: [.large])) { [factory] close in
      factory.makeMelodyPicker(selectedID: current, store: store, routes: MelodyPickerRoutes(
        record: { [weak self] saved in self?.recordMelody(store: store, saved: saved) },
        done: { id in
          close()
          picked(id)
        }))
    }
  }

  private func recordMelody(store: any MelodyStore, saved: @escaping @MainActor (Melody) -> Void) {
    navigator.present(style: .sheet(detents: [.large])) { [factory] close in
      factory.makeRecordMelody(store: store) { melody in
        close()
        if let melody { saved(melody) }
      }
    }
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

  /// Now, or after the start delay.
  private func begin(_ preferences: AppPreferences) {
    let minutes = RecordingDelay.valid(preferences.recordingDelayMinutes)
    guard minutes > 0 else { return startNight(capture: factory.makeCapture(), preferences: preferences) }
    showCountdown(minutes: minutes, preferences: preferences)
  }

  /// The start delay: the microphone stays warm (so the app keeps running
  /// with the screen locked), a notification says when the night starts, and
  /// the screen stays on as on the bedside clock.
  private func showCountdown(minutes: Int, preferences: AppPreferences) {
    let capture = factory.makeCapture()
    do {
      try capture.warmUp()
    } catch {
      Log.app.error("Warm-up failed; the countdown may pause in the background: \(error.localizedDescription, privacy: .public)")
    }
    warmCapture = capture
    let target = Date().addingTimeInterval(TimeInterval(minutes * 60))
    device.scheduleStartNotification(target)
    device.keepScreenOn(true)
    navigator.setRoot(factory.makeCountdown(target: target, routes: RecordingCountdownRoutes(
      cancel: { [weak self] in self?.cancelCountdown() },
      start: { [weak self] in self?.endCountdown(preferences: preferences) })))
  }

  private func cancelCountdown() {
    warmCapture?.coolDown()
    warmCapture = nil
    device.cancelStartNotification()
    device.keepScreenOn(false)
    start()
  }

  private func endCountdown(preferences: AppPreferences) {
    guard let capture = warmCapture else { return }
    warmCapture = nil
    device.cancelStartNotification()
    startNight(capture: capture, preferences: preferences)
  }

  private func startNight(capture: any AudioCapture, preferences: AppPreferences) {
    let model = factory.makeModel(capture: capture, preferences: preferences)
    self.model = model
    device.keepScreenOn(true)
    batteryWatch = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: Self.batteryCheckInterval)
        self?.checkBattery()
      }
    }
    navigator.setRoot(factory.makeBedside(model: model, routes: BedsideClockRoutes(
      finished: { [weak self] night in self?.showSummary(night) },
      discarded: { [weak self] night in self?.discard(night) })))
  }

  private func showSummary(_ night: Night) {
    stopWatching()
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
