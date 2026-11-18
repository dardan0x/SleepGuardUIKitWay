import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import UIKit

/// Choosing the interrupter's sound, drawn from `MelodyPickerViewModel` in
/// the shared picker; the preview stops when the screen goes away.
public final class MelodyPickerViewController: ScreenController {
  let viewModel: MelodyPickerViewModel

  public init(viewModel: MelodyPickerViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    renderTracking { [weak self] in self?.redraw() }
  }

  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    viewModel.reload()
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    viewModel.stopPreview()
  }

  private func redraw() {
    let viewModel = viewModel
    render(MelodyPickerContent(
      custom: viewModel.recordings, selectedID: viewModel.selectedID, previewingID: viewModel.previewingID,
      onRecord: { viewModel.record() }, onSelect: { viewModel.select($0) }, onDelete: { viewModel.delete($0) },
      onDone: { viewModel.done() }))
  }
}
