import ScreenKit
import SleepCore
import SleepGuardContentKit
import SwiftUI
import UIKit

/// The screen left on the nightstand while recording, drawn from
/// `BedsideClockViewModel` in the shared `BedsideClockContent`: redraws every
/// second and whenever the night changes. With the Snore Interrupter on, a
/// note to mute it for the night, and the melody's controls while it plays.
public final class BedsideClockViewController: ScreenController {
  let viewModel: BedsideClockViewModel
  private var running: Task<Void, Never>?
  private var ticking: Task<Void, Never>?
  private var stopping: Task<Void, Never>?

  public init(viewModel: BedsideClockViewModel, theme: Theme, chrome: ScreenChrome) {
    self.viewModel = viewModel
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    running?.cancel()
    ticking?.cancel()
    stopping?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    renderTracking { [weak self] in self?.redraw() }
    running = Task { [viewModel] in await viewModel.run() }
    ticking = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
        self?.redraw()
      }
    }
  }

  private func redraw(now: Date = Date()) {
    let live = viewModel.live
    render(BedsideClockContent(
      time: now, elapsed: now.timeIntervalSince(live.start), eventCount: live.eventCount, db: live.db,
      snoreState: live.snoreState, canStop: live.phase == .recording,
      onStop: { [weak self] in self?.perform { await $0.stop() } },
      banner: {
        if live.interrupterArmed {
          BedsideMelodyDisclaimer(onMute: live.muteInterrupter)
            .padding(.top, 10)
            .padding(.horizontal, 20)
        }
      },
      overlay: {
        if let melody = live.playingMelody {
          BedsideMelodyOverlay(melodyName: melody.name, onMute: live.muteInterrupter, onStop: live.stopMelody)
        }
      }))
    presentAlert(viewModel.alert, make: alert(for:))
  }

  private func perform(_ work: @escaping @MainActor (BedsideClockViewModel) async -> Void) {
    guard stopping == nil else { return }
    stopping = Task { [weak self, viewModel] in
      await work(viewModel)
      self?.stopping = nil
    }
  }

  func alert(for due: BedsideClockViewModel.Alert) -> UIAlertController {
    let viewModel = viewModel
    switch due {
    case .earlyStop:
      let alert = UIAlertController(
        title: Strings.sessionSummaryTooShortTitle,
        message: String(format: Strings.sessionSummaryTooShortMessageFormat, Int(Night.minimumSaveDuration / 60)),
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: Strings.actionKeepRecording, style: .cancel) { _ in viewModel.keepRecording() })
      alert.addAction(UIAlertAction(title: Strings.actionStopAnyway, style: .default) { [weak self] _ in
        self?.perform { await $0.stopAnyway() }
      })
      return alert
    case .startFailed:
      let alert = UIAlertController(
        title: Strings.sessionStartFailedAlertTitle, message: Strings.sessionStartFailedAlertMessage, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: Strings.actionOk, style: .cancel) { _ in viewModel.acknowledgeFailure() })
      return alert
    }
  }
}
