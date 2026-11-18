import Foundation
import Observation
import SleepCore
import SleepDomain

/// The bedside clock's decisions over the live night (`LiveRecordingModel`):
/// Stop before `Night.minimumSaveDuration` asks first; a microphone that
/// never started is reported once; a stopped night goes to the summary or is
/// discarded.
@MainActor
@Observable
public final class BedsideClockViewModel {
  public enum Alert: Equatable {
    /// Stopping now discards the night: keep recording, or stop anyway.
    case earlyStop
    /// The microphone never started.
    case startFailed
  }

  public let live: LiveRecordingModel
  let routes: BedsideClockRoutes
  private var askingToStop = false
  private var failureAcknowledged = false
  private var stopping = false

  public init(live: LiveRecordingModel, routes: BedsideClockRoutes) {
    self.live = live
    self.routes = routes
  }

  public var alert: Alert? {
    if live.phase == .failed, !failureAcknowledged { return .startFailed }
    return askingToStop ? .earlyStop : nil
  }

  /// Listens until the night stops.
  public func run() async {
    await live.run()
  }

  public func stop(at now: Date = Date()) async {
    guard !live.isTooShort(at: now) else {
      askingToStop = true
      return
    }
    await finish(then: routes.finished)
  }

  public func keepRecording() {
    askingToStop = false
  }

  public func stopAnyway() async {
    askingToStop = false
    let discarded = routes.discarded
    await finish { discarded($0) }
  }

  public func acknowledgeFailure() {
    failureAcknowledged = true
    routes.discarded(nil)
  }

  private func finish(then route: @escaping @MainActor (Night) -> Void) async {
    guard !stopping else { return }
    stopping = true
    await route(live.stop())
  }
}
