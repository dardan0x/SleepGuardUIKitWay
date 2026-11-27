import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import SleepGuardDesignKit
import SwiftUI
import UIKit

/// The Snore Interrupter's settings, drawn from `SnoreInterrupterViewModel`
/// in the shared content.
public final class SnoreInterrupterViewController: ScreenController {
  let viewModel: SnoreInterrupterViewModel

  public init(viewModel: SnoreInterrupterViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    renderTracking { [weak self] in self?.redraw() }
  }

  private func redraw() {
    let viewModel = viewModel
    let shownMode = viewModel.draft.mode
    render(SnoreInterrupterSettingsContent(
      mode: Binding(get: { shownMode }, set: { viewModel.setMode($0) }),
      melodyName: viewModel.melodyName,
      onSound: { viewModel.chooseSound() },
      onSave: { viewModel.save() },
      onCancel: { viewModel.cancel() }))
  }
}
