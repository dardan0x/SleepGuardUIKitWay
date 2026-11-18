import Foundation
import ScreenKit
import SleepCore
import SleepGuardContentKit
import UIKit

/// The start delay, counting down to `target` in the shared
/// `RecordingCountdownContent`. At zero, or on Start now, the night starts;
/// Cancel goes back to the prestart. The shell keeps the microphone warm
/// meanwhile, so the app isn't suspended.
public final class RecordingCountdownViewController: ScreenController {
  let target: Date
  let routes: RecordingCountdownRoutes
  private(set) var seconds: Int
  private var ticking: Task<Void, Never>?

  public init(target: Date, routes: RecordingCountdownRoutes, theme: Theme, chrome: ScreenChrome) {
    self.target = target
    self.routes = routes
    seconds = RecordingDelay.secondsLeft(until: target, now: Date())
    super.init(theme: theme, chrome: chrome)
  }

  deinit {
    ticking?.cancel()
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    redraw()
  }

  override public func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)
    guard ticking == nil else { return }
    ticking = Task { [weak self] in
      while !Task.isCancelled, let self {
        if tick() { return }
        try? await Task.sleep(for: .seconds(1))
      }
    }
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    ticking?.cancel()
    ticking = nil
  }

  /// Counts down; at zero starts the night and returns `true`. Internal for tests.
  func tick(now: Date = Date()) -> Bool {
    seconds = RecordingDelay.secondsLeft(until: target, now: now)
    redraw()
    guard seconds == 0 else { return false }
    routes.start()
    return true
  }

  private func redraw() {
    render(RecordingCountdownContent(seconds: seconds, onCancel: routes.cancel, onStartNow: routes.start))
  }
}
