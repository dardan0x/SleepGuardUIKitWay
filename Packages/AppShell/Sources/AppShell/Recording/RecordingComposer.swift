import FactoryKit
import RecordingFeature
import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardDesignKit
import SwiftUI
import UIKit

/// Builds the recording screens. Wiring only: resolve, build, host. They show
/// no navigation bar: the flow is a full-screen modal with its own buttons.
struct RecordingComposer {
  let container: Container
  /// SleepGuard's compact layout for screens up to 874 pt tall.
  let compactHeight: Bool

  func makePrestart(routes: RecordingPrestartRoutes) -> UIViewController {
    let capture = container.makeAudioCapture()()
    let device = container.deviceServices()
    let preferences = container.preferencesStore()
    return host(RecordingPrestartScreen(
      dependencies: RecordingPrestartDependencies(
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
        hasInterrupter: melodyStore != nil),
      routes: routes))
  }

  /// The Snore Interrupter's sounds; `nil` in a brand without it.
  var melodyStore: (any MelodyStore)? {
    container.makeMelodyStore()?()
  }

  func makeInterrupterSettings(
    choice: SnoreInterrupterChoice, store: any MelodyStore, routes: SnoreInterrupterRoutes) -> UIViewController
  {
    host(SnoreInterrupterScreen(choice: choice, store: store, routes: routes))
  }

  func makeMelodyPicker(selectedID: Int, store: any MelodyStore, routes: MelodyPickerRoutes) -> UIViewController {
    host(MelodyPickerScreen(
      selectedID: selectedID, store: store, preview: container.makeMelodyPlayer()(true), routes: routes))
  }

  func makeRecordMelody(store: any MelodyStore, done: @escaping @MainActor (Melody?) -> Void) -> UIViewController {
    host(RecordMelodyScreen(
      store: store, recorder: container.makeMelodyRecorder()(), playback: container.makeMelodyPlayer()(true),
      done: done))
  }

  /// A new microphone capture for one night (warmed up first when the night
  /// starts after a delay).
  func makeCapture() -> any AudioCapturePort {
    container.makeAudioCapture()()
  }

  /// A night's model over `capture`, with the Settings choices and, in a
  /// brand that has it, the Snore Interrupter over the same capture. The raw
  /// recording is kept only in Debug builds, when switched on.
  func makeModel(capture: any AudioCapturePort, preferences: AppPreferences) -> LiveRecordingModel {
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
      checkpoints: container.checkpointStore(),
      rawLog: preserveRawAudio ? container.makeRawLogWriter()() : nil,
      interrupter: melodyStore.map { store in
        SnoreInterrupter(
          mode: preferences.interrupterMode, melodyID: preferences.melodyID,
          player: container.makeMelodyPlayer()(false), store: store, capture: capture)
      })
  }

  func makeCountdown(target: Date, routes: RecordingCountdownRoutes) -> UIViewController {
    host(RecordingCountdownScreen(target: target, routes: routes))
  }

  func makeBedside(model: LiveRecordingModel, routes: BedsideClockRoutes) -> UIViewController {
    host(BedsideClockScreen(model: model, routes: routes))
  }

  func makeSummary(night: Night, routes: SessionSummaryRoutes) -> UIViewController {
    host(SessionSummaryScreen(night: night, routes: routes))
  }

  /// "Couldn't save", with OK.
  func makeSaveFailedAlert() -> UIViewController {
    let alert = UIAlertController(title: Strings.saveFailed, message: Strings.unableToSaveTheSession, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionOk, style: .cancel))
    return alert
  }

  private func host(_ screen: some View) -> UIViewController {
    HostingScreen(rootView: screen, theme: container.theme(), chrome: ScreenChrome(hidesNavigationBar: true))
  }
}
