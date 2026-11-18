import Foundation
import Observation
import SleepCore
import SleepDomain

/// Before a night: the settings for it (start delay, Snore Interrupter), and
/// Start, which checks the microphone and the charger first, as SleepGuard's
/// prestart does.
@MainActor
@Observable
public final class RecordingPrestartViewModel {
  public enum Alert: Equatable {
    /// The microphone isn't allowed: open Settings, or cancel.
    case microphone
    /// Not charging: start anyway, or cancel.
    case charging
  }

  public private(set) var preferences: AppPreferences?
  public private(set) var alert: Alert?
  let dependencies: RecordingPrestartDependencies
  let routes: RecordingPrestartRoutes

  public init(dependencies: RecordingPrestartDependencies, routes: RecordingPrestartRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public var compact: Bool {
    dependencies.compactHeight
  }

  public var delayMinutes: Int {
    preferences?.recordingDelayMinutes ?? 0
  }

  /// `nil` in a brand without the Snore Interrupter: no row.
  public var interrupterMode: SnoreInterrupterMode? {
    dependencies.hasInterrupter ? preferences?.interrupterMode ?? .never : nil
  }

  public func load() async {
    let loaded = await dependencies.loadPreferences()
    if !Task.isCancelled { preferences = loaded }
  }

  public func setDelay(_ minutes: Int) {
    preferences?.recordingDelayMinutes = minutes
    dependencies.saveDelay(minutes)
  }

  public func openInterrupter() {
    routes.openInterrupter { [weak self] choice in
      self?.preferences?.interrupterMode = choice.mode
      self?.preferences?.melodyID = choice.melodyID
    }
  }

  /// Start: microphone allowed, then charging, then the night.
  public func start() async {
    if preferences == nil { preferences = await dependencies.loadPreferences() }
    guard await dependencies.requestPermission() else {
      alert = .microphone
      return
    }
    guard dependencies.isCharging() else {
      alert = .charging
      return
    }
    routes.start(preferences ?? AppPreferences())
  }

  public func startAnyway() {
    alert = nil
    routes.start(preferences ?? AppPreferences())
  }

  public func openSettings() {
    alert = nil
    routes.openSettings()
  }

  public func dismissAlert() {
    alert = nil
  }

  public func cancel() {
    routes.cancel()
  }
}
