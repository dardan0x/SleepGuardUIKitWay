import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import UIKit

/// Settings, drawn from `SettingsViewModel` by the shared `SettingsContent`;
/// the confirmations and reports are UIKit alerts. The values handed to the
/// content are built in `SettingsViewController+Values.swift`.
public final class SettingsViewController: ScreenController {
  let viewModel: SettingsViewModel
  private var loading: Task<Void, Never>?

  public init(viewModel: SettingsViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    loading?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    renderTracking { [weak self] in self?.redraw() }
    loading = Task { [viewModel] in await viewModel.load() }
  }

  private func redraw() {
    guard let preferences = viewModel.preferences else { return }
    render(SettingsContent(
      permissions: permissions, recording: recording(preferences), profile: profile(preferences), watch: nil,
      storage: storage(preferences), data: data(preferences), about: about))
    presentAlert(viewModel.alert, make: alert(for:))
  }

  func alert(for due: SettingsViewModel.Alert) -> UIAlertController {
    let viewModel = viewModel
    switch due {
    case .confirmDeleteAll:
      return confirmation(
        Strings.settingsDeleteAllConfirmTitle, Strings.settingsDeleteAllConfirmMessage, action: Strings.actionDeleteAll)
      { viewModel.confirmDeleteAll() }
    case .confirmLowerLimit:
      return confirmation(
        Strings.settingsLowerStorageLimitTitle, Strings.settingsLowerStorageLimitMessage, action: Strings.actionDelete)
      { viewModel.confirmLowerLimit() }
    case let .cleanup(report):
      return notice(Strings.settingsTestCleanup, String(
        format: Strings.settingsTestCleanupResultFormat, report.filesRemoved, Int(report.bytesRemoved / 1_024 / 1_024),
        report.nightsAffected, report.dayLimitNights, report.sizeLimitNights))
    case .failed:
      return notice(Strings.recordingsErrorTitle, Strings.recordingsErrorMessage)
    }
  }

  /// Cancel and a destructive `action`.
  private func confirmation(
    _ title: String, _ message: String, action: String, perform: @escaping @MainActor () -> Void) -> UIAlertController
  {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionCancel, style: .cancel) { [viewModel] _ in viewModel.dismissAlert() })
    alert.addAction(UIAlertAction(title: action, style: .destructive) { _ in perform() })
    return alert
  }

  private func notice(_ title: String, _ message: String) -> UIAlertController {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionOk, style: .default) { [viewModel] _ in viewModel.dismissAlert() })
    return alert
  }
}
