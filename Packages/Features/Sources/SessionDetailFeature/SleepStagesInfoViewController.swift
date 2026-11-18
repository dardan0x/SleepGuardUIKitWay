import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

/// The sleep-stages sheet, drawn from `SleepStagesInfoViewModel` by the
/// shared `SleepStagesInfoContent` with its own close button.
public final class SleepStagesInfoViewController: ScreenController {
  let viewModel: SleepStagesInfoViewModel

  public init(viewModel: SleepStagesInfoViewModel, theme: Theme, chrome: ScreenChrome = ScreenChrome()) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    let viewModel = viewModel
    render(SleepStagesInfoContent(breakdown: viewModel.breakdown) { viewModel.close() })
  }
}
