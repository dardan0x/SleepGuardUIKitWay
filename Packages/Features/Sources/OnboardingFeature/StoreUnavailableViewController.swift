import ScreenKit
import SleepGuardContentKit
import UIKit

/// The store-unavailable screen, drawn by the shared `StoreUnavailableContent`.
public final class StoreUnavailableViewController: ScreenController {
  let viewModel: StoreUnavailableViewModel

  public init(viewModel: StoreUnavailableViewModel, theme: Theme) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: ScreenChrome(hidesNavigationBar: true))
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    render(StoreUnavailableContent(onUpdate: viewModel.update.map { update in { update() } }))
  }
}
