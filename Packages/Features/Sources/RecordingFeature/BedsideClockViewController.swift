import ScreenKit
import SleepCore
import SleepGuardContentKit
import SwiftUI
import UIKit

/// The screen left on the nightstand while recording, in the shared
/// `BedsideClockContent`: events so far, a dim clock, how long it has been
/// recording with a level meter, the current snoring tier, and Stop. Redraws
/// every second and whenever the model changes. Stopping before
/// `Night.minimumSaveDuration` asks first, as SleepGuard's does. With the
/// Snore Interrupter on, a note to mute it for the night, and the melody's
/// controls while it plays.
public final class BedsideClockViewController: ScreenController {
  let model: LiveRecordingModel
  let routes: BedsideClockRoutes
  private var running: Task<Void, Never>?
  private var ticking: Task<Void, Never>?
  private var stopping: Task<Void, Never>?
  private var showedFailure = false

  public init(model: LiveRecordingModel, routes: BedsideClockRoutes, theme: Theme, chrome: ScreenChrome) {
    self.model = model
    self.routes = routes
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
    running = Task { [model] in await model.run() }
    ticking = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
        self?.redraw()
      }
    }
  }

  private func redraw(now: Date = Date()) {
    let model = model
    render(BedsideClockContent(
      time: now, elapsed: now.timeIntervalSince(model.start), eventCount: model.eventCount, db: model.db,
      snoreState: model.snoreState, canStop: model.phase == .recording,
      onStop: { [weak self] in self?.stopTapped() },
      banner: {
        if model.interrupterArmed {
          BedsideMelodyDisclaimer(onMute: model.muteInterrupter)
            .padding(.top, 10)
            .padding(.horizontal, 20)
        }
      },
      overlay: {
        if let melody = model.playingMelody {
          BedsideMelodyOverlay(melodyName: melody.name, onMute: model.muteInterrupter, onStop: model.stopMelody)
        }
      }))
    if model.phase == .failed, !showedFailure {
      showedFailure = true
      present(startFailedAlert(), animated: true)
    }
  }

  /// Internal for tests.
  func stopTapped(at now: Date = Date()) {
    if model.isTooShort(at: now) { return present(earlyStopAlert(), animated: true) }
    stop(then: routes.finished)
  }

  private func stop(then route: @escaping @MainActor (Night) -> Void) {
    guard stopping == nil else { return }
    stopping = Task { [model] in await route(model.stop()) }
  }

  func earlyStopAlert() -> UIAlertController {
    let alert = UIAlertController(
      title: Strings.sessionSummaryTooShortTitle,
      message: String(format: Strings.sessionSummaryTooShortMessageFormat, Int(Night.minimumSaveDuration / 60)),
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: Strings.actionKeepRecording, style: .cancel))
    alert.addAction(UIAlertAction(title: Strings.actionStopAnyway, style: .default) { [weak self] _ in
      guard let self else { return }
      let discarded = routes.discarded
      stop { discarded($0) }
    })
    return alert
  }

  func startFailedAlert() -> UIAlertController {
    let alert = UIAlertController(
      title: Strings.sessionStartFailedAlertTitle, message: Strings.sessionStartFailedAlertMessage, preferredStyle: .alert)
    let discarded = routes.discarded
    alert.addAction(UIAlertAction(title: Strings.actionOk, style: .cancel) { _ in discarded(nil) })
    return alert
  }
}
