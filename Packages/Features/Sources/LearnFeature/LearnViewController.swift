import ScreenKit
import SleepGuardContentKit
import SleepGuardDesignKit
import UIKit

/// The Learn tab, drawn from `LearnViewModel` by the shared `LearnContent`.
public final class LearnViewController: ScreenController {
  let viewModel: LearnViewModel

  public init(viewModel: LearnViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    render(LearnContent(url: viewModel.url))
  }
}
