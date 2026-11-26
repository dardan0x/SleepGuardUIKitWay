import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

/// The night just recorded, drawn from `SessionSummaryViewModel` in the
/// shared `SessionSummaryContent`; the too-short alert is UIKit.
public final class SessionSummaryViewController: ScreenController {
  let viewModel: SessionSummaryViewModel

  public init(viewModel: SessionSummaryViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    let viewModel = viewModel
    render(SessionSummaryContent(
      night: viewModel.night, summary: viewModel.summary,
      onSave: { viewModel.save() }, onDiscard: { viewModel.discard() }))
    renderTracking { [weak self] in
      guard let self else { return }
      presentAlert(viewModel.alert, make: alert(for:))
    }
  }

  func alert(for _: SessionSummaryViewModel.Alert) -> UIAlertController {
    let alert = UIAlertController(
      title: Strings.sessionSummaryTooShortTitle,
      message: String(format: Strings.sessionSummaryTooShortInfoFormat, Int(viewModel.saveRules.minimumDuration / 60)),
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionOk, style: .cancel) { [viewModel] _ in viewModel.dismissAlert() })
    return alert
  }
}
