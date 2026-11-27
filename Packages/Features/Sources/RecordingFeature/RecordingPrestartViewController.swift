import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import SleepGuardDesignKit
import SleepStrings
import SwiftUI
import UIKit

/// Before a night, drawn from `RecordingPrestartViewModel`: the shared
/// `PrestartContent` with the start delay and, for a brand that has it, the
/// Snore Interrupter row in its options slot; the microphone and charging
/// alerts are UIKit.
public final class RecordingPrestartViewController: ScreenController {
  let viewModel: RecordingPrestartViewModel
  private var loading: Task<Void, Never>?
  private(set) var starting: Task<Void, Never>?

  public init(viewModel: RecordingPrestartViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    loading?.cancel()
    starting?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    renderTracking { [weak self] in self?.redraw() }
    loading = Task { [viewModel] in await viewModel.load() }
  }

  private func redraw() {
    let viewModel = viewModel
    let shownDelay = viewModel.delayMinutes
    let delay = Binding(get: { shownDelay }, set: { viewModel.setDelay($0) })
    let mode = viewModel.interrupterMode
    render(PrestartContent(
      compact: viewModel.compact, onStart: { [weak self] in self?.start() }, onCancel: { viewModel.cancel() })
    {
      PrestartOptions(delayMinutes: delay, interrupterMode: mode) { viewModel.openInterrupter() }
    })
    presentAlert(viewModel.alert, make: alert(for:))
  }

  private func start() {
    guard starting == nil else { return }
    starting = Task { [weak self, viewModel] in
      await viewModel.start()
      self?.starting = nil
    }
  }

  func alert(for due: RecordingPrestartViewModel.Alert) -> UIAlertController {
    let viewModel = viewModel
    let alert: UIAlertController
    switch due {
    case .microphone:
      alert = UIAlertController(
        title: Strings.sessionMicrophoneAlertTitle, message: Strings.sessionMicrophoneAlertMessage, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: Strings.sessionMicrophoneAlertOpenSettings, style: .default) { _ in
        viewModel.openSettings()
      })
    case .charging:
      alert = UIAlertController(
        title: Strings.sessionChargingAlertTitle, message: Strings.sessionChargingAlertMessage, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: Strings.sessionChargingAlertStartAnyway, style: .default) { _ in
        viewModel.startAnyway()
      })
    }
    alert.addAction(UIAlertAction(title: Strings.actionCancel, style: .cancel) { _ in viewModel.dismissAlert() })
    return alert
  }
}
