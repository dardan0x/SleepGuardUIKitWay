import FactoryKit
import RecordingFeature
import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SleepStrings
import UIKit

/// Builds the recording screens: dependencies, then the view model, then the
/// screen (ADR 0008). Wiring only. They show
/// no navigation bar: the flow is a full-screen modal with its own buttons.
struct RecordingFactory {
  let container: Container
  /// SleepGuard's compact layout for screens up to 874 pt tall.
  let compactHeight: Bool

  func makePrestart(routes: RecordingPrestartRoutes) -> UIViewController {
    let capture = container.makeAudioCapture()()
    let device = container.deviceServices()
    let preferences = container.preferencesStore()
    let dependencies = RecordingPrestartDependencies(
      compactHeight: compactHeight,
      requestPermission: { await capture.requestPermission() },
      isCharging: device.isCharging,
      loadPreferences: { await preferences.load() },
      saveDelay: { minutes in
        Task {
          var stored = await preferences.load()
          stored.recordingDelayMinutes = minutes
          await preferences.save(stored)
        }
      },
      hasInterrupter: melodyStore != nil)
    return RecordingPrestartViewController(
      viewModel: RecordingPrestartViewModel(dependencies: dependencies, routes: routes), theme: theme, chrome: chrome)
  }

  /// The Snore Interrupter's sounds; `nil` in a brand without it.
  var melodyStore: (any MelodyStore)? {
    container.makeMelodyStore()?()
  }

  func makeInterrupterSettings(
    choice: SnoreInterrupterChoice, store: any MelodyStore, routes: SnoreInterrupterRoutes) -> UIViewController
  {
    SnoreInterrupterViewController(
      viewModel: SnoreInterrupterViewModel(choice: choice, store: store, routes: routes), theme: theme, chrome: chrome)
  }

  func makeMelodyPicker(selectedID: Int, store: any MelodyStore, routes: MelodyPickerRoutes) -> UIViewController {
    let viewModel = MelodyPickerViewModel(
      selectedID: selectedID, store: store, preview: container.makeMelodyPlayer()(true), routes: routes)
    return MelodyPickerViewController(viewModel: viewModel, theme: theme, chrome: chrome)
  }

  func makeRecordMelody(store: any MelodyStore, done: @escaping @MainActor (Melody?) -> Void) -> UIViewController {
    let viewModel = RecordMelodyViewModel(
      store: store, recorder: container.makeMelodyRecorder()(), playback: container.makeMelodyPlayer()(true), done: done)
    return RecordMelodyViewController(viewModel: viewModel, theme: theme, chrome: chrome)
  }

  /// A new microphone capture for one night (warmed up first when the night
  /// starts after a delay).
  func makeCapture() -> any AudioCapture {
    container.makeAudioCapture()()
  }

  /// A night's model over `capture`, with the Settings choices and, in a
  /// brand that has it, the Snore Interrupter over the same capture. The raw
  /// recording is kept only in Debug builds, when switched on.
  func makeModel(capture: any AudioCapture, preferences: AppPreferences) -> LiveRecordingModel {
    #if DEBUG
    let preserveRawAudio = preferences.preserveRawAudio
    #else
    let preserveRawAudio = false
    #endif
    return LiveRecordingModel(
      capture: capture,
      settings: RecordingSession.Settings(
        sensitivity: preferences.sensitivity, detectSleepTalking: preferences.detectSleepTalking,
        preserveRawAudio: preserveRawAudio),
      saveRules: container.saveRules(),
      checkpoints: container.checkpointStore(),
      rawLog: preserveRawAudio ? container.makeRawLogWriter()() : nil,
      interrupter: melodyStore.map { store in
        SnoreInterrupter(
          mode: preferences.interrupterMode, melodyID: preferences.melodyID,
          player: container.makeMelodyPlayer()(false), store: store, capture: capture)
      })
  }

  func makeCountdown(target: Date, routes: RecordingCountdownRoutes) -> UIViewController {
    RecordingCountdownViewController(
      viewModel: RecordingCountdownViewModel(target: target, routes: routes), theme: theme, chrome: chrome)
  }

  func makeBedside(model: LiveRecordingModel, routes: BedsideClockRoutes) -> UIViewController {
    BedsideClockViewController(
      viewModel: BedsideClockViewModel(live: model, routes: routes), theme: theme, chrome: chrome)
  }

  func makeSummary(night: Night, routes: SessionSummaryRoutes) -> UIViewController {
    SessionSummaryViewController(
      viewModel: SessionSummaryViewModel(night: night, saveRules: container.saveRules(), routes: routes),
      theme: theme, chrome: chrome)
  }

  /// "Couldn't save", with OK.
  func makeSaveFailedAlert() -> UIViewController {
    let alert = UIAlertController(title: Strings.saveFailed, message: Strings.unableToSaveTheSession, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionOk, style: .cancel))
    return alert
  }

  private var theme: Theme {
    container.theme()
  }

  /// No bar: the flow is a full-screen modal with its own buttons.
  private var chrome: ScreenChrome {
    ScreenChrome(hidesNavigationBar: true)
  }
}
