import ScreenKit
import SleepCore
import SleepDomain
import SleepGuardContentKit
import UIKit

/// Recording a sound of one's own, drawn from `RecordMelodyViewModel` in the
/// shared `RecordMelodyContent`; redraws ten times a second for the elapsed
/// time while shown.
public final class RecordMelodyViewController: ScreenController {
  let viewModel: RecordMelodyViewModel
  private var ticking: Task<Void, Never>?

  public init(viewModel: RecordMelodyViewModel, theme: Theme, chrome: ScreenChrome) {
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
    ticking = Task { [weak self, viewModel] in
      await viewModel.requestPermission()
      while !Task.isCancelled {
        self?.redraw()
        try? await Task.sleep(for: .milliseconds(100))
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
    render(RecordMelodyContent(
      state: Self.content(viewModel.state), elapsed: viewModel.elapsed, canRecord: viewModel.canRecord,
      onRecordToggle: { viewModel.toggleRecording() }, onPlayToggle: { viewModel.togglePlayback() },
      onSave: { viewModel.save() }, onReRecord: { viewModel.reRecord() }, onBack: { viewModel.back() }))
  }

  private static func content(_ state: RecordMelodyViewModel.State) -> MelodyRecordingState {
    switch state {
    case .idle: .idle
    case .recording: .recording
    case let .recorded(isPlaying): .recorded(isPlaying: isPlaying)
    }
  }
}
