import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import SwiftUI
import UIKit

/// Before a night: the shared `PrestartContent`, with the start delay and,
/// for a brand that has it, the Snore Interrupter row in its options slot.
/// Start checks the microphone and the charger first, as SleepGuard's
/// prestart does.
public final class RecordingPrestartViewController: ScreenController {
  let dependencies: RecordingPrestartDependencies
  let routes: RecordingPrestartRoutes
  private(set) var preferences: AppPreferences?
  private var loading: Task<Void, Never>?
  private var starting: Task<Void, Never>?

  public init(
    dependencies: RecordingPrestartDependencies, routes: RecordingPrestartRoutes, theme: Theme, chrome: ScreenChrome)
  {
    self.dependencies = dependencies
    self.routes = routes
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    loading?.cancel()
    starting?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    redraw()
    loading = Task { [weak self, dependencies] in
      let preferences = await dependencies.loadPreferences()
      guard !Task.isCancelled else { return }
      self?.preferences = preferences
      self?.redraw()
    }
  }

  private func redraw() {
    let delay = Binding(
      get: { [weak self] in self?.preferences?.recordingDelayMinutes ?? 0 },
      set: { [weak self] in self?.setDelay($0) })
    let mode = dependencies.hasInterrupter ? preferences?.interrupterMode ?? .never : nil
    let routes = routes
    render(PrestartContent(
      compact: dependencies.compactHeight,
      onStart: { [weak self] in self?.startTapped() },
      onCancel: routes.cancel)
    {
      PrestartOptions(delayMinutes: delay, interrupterMode: mode) { [weak self] in self?.openInterrupter() }
    })
  }

  private func setDelay(_ minutes: Int) {
    preferences?.recordingDelayMinutes = minutes
    dependencies.saveDelay(minutes)
    redraw()
  }

  private func openInterrupter() {
    routes.openInterrupter { [weak self] choice in
      self?.preferences?.interrupterMode = choice.mode
      self?.preferences?.melodyID = choice.melodyID
      self?.redraw()
    }
  }

  /// Internal for tests.
  func startTapped() {
    guard starting == nil else { return }
    starting = Task { [weak self] in
      await self?.checkAndStart()
      self?.starting = nil
    }
  }

  private func checkAndStart() async {
    if preferences == nil { preferences = await dependencies.loadPreferences() }
    guard await dependencies.requestPermission() else { return present(microphoneAlert(), animated: true) }
    guard dependencies.isCharging() else { return present(chargingAlert(), animated: true) }
    routes.start(preferences ?? AppPreferences())
  }

  func microphoneAlert() -> UIAlertController {
    let alert = UIAlertController(
      title: Strings.sessionMicrophoneAlertTitle, message: Strings.sessionMicrophoneAlertMessage, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionCancel, style: .cancel))
    let open = routes.openSettings
    alert.addAction(UIAlertAction(title: Strings.sessionMicrophoneAlertOpenSettings, style: .default) { _ in open() })
    return alert
  }

  func chargingAlert() -> UIAlertController {
    let alert = UIAlertController(
      title: Strings.sessionChargingAlertTitle, message: Strings.sessionChargingAlertMessage, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionCancel, style: .cancel))
    alert.addAction(UIAlertAction(title: Strings.sessionChargingAlertStartAnyway, style: .default) { [weak self] _ in
      guard let self else { return }
      routes.start(preferences ?? AppPreferences())
    })
    return alert
  }
}
