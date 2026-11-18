import Foundation
import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

/// The start delay, drawn from `RecordingCountdownViewModel` in the shared
/// `RecordingCountdownContent`, ticking once a second while shown. The shell
/// keeps the microphone warm meanwhile, so the app isn't suspended.
public final class RecordingCountdownViewController: ScreenController {
  let viewModel: RecordingCountdownViewModel
  private var ticking: Task<Void, Never>?

  public init(viewModel: RecordingCountdownViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    ticking?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    renderTracking { [weak self] in self?.redraw() }
  }

  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    guard ticking == nil else { return }
    ticking = Task { [viewModel] in
      while !Task.isCancelled, !viewModel.tick() {
        try? await Task.sleep(for: .seconds(1))
      }
    }
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    ticking?.cancel()
    ticking = nil
  }

  private func redraw() {
    let viewModel = viewModel
    render(RecordingCountdownContent(
      seconds: viewModel.seconds, onCancel: { viewModel.cancel() }, onStartNow: { viewModel.startNow() }))
  }
}
