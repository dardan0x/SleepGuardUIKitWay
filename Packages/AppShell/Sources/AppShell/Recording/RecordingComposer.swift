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
    return host(RecordingPrestartScreen(
      dependencies: RecordingPrestartDependencies(
        compactHeight: compactHeight,
        requestPermission: { await capture.requestPermission() },
        isCharging: device.isCharging),
      routes: routes))
  }

  /// A night's model over a new capture. Sensitivity and sleep talking are
  /// SleepGuard's defaults (medium, off) until Settings arrives (F8).
  func makeModel() -> LiveRecordingModel {
    LiveRecordingModel(
      capture: container.makeAudioCapture()(),
      settings: RecordingSession.Settings(sensitivity: .medium, detectSleepTalking: false),
      checkpoints: container.checkpointStore())
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
