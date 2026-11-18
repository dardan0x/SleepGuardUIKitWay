import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

/// The morning briefing sheet, drawn from `BriefingViewModel` by the shared
/// `BriefingContent`.
public final class BriefingViewController: ScreenController {
  let viewModel: BriefingViewModel

  public init(viewModel: BriefingViewModel, theme: Theme, chrome: ScreenChrome = ScreenChrome()) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    let viewModel = viewModel
    render(BriefingContent(
      briefing: viewModel.briefing, onChip: { viewModel.answer($0) }, onClose: { viewModel.close() }))
  }
}
