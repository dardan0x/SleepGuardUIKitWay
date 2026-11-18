import Foundation
import Observation
import SleepCore
import SleepDomain

/// Settings' state and intents. Holds the preferences while shown and writes
/// each change back, in order; asks before deleting everything and before
/// lowering the storage limit (which removes audio at once). Rows for what
/// the brand lacks (Apple Health, an App Store page) aren't offered.
@MainActor
@Observable
public final class SettingsViewModel {
  public enum Alert: Equatable {
    case confirmDeleteAll
    case confirmLowerLimit(megabytes: Int)
    case cleanup(EnforceStorageLimits.Report)
    case failed
  }

  /// `nil` until loaded.
  public private(set) var preferences: AppPreferences?
  public private(set) var microphone: PermissionState = .notDetermined
  public private(set) var notifications: PermissionState = .notDetermined
  public private(set) var alert: Alert?
  /// The last queued write or cleanup; awaited by tests.
  public private(set) var working: Task<Void, Never>?
  let dependencies: SettingsDependencies
  let routes: SettingsRoutes

  public init(dependencies: SettingsDependencies, routes: SettingsRoutes) {
    self.dependencies = dependencies
    self.routes = routes
  }

  public var version: String { dependencies.version }
  public var showsDebugRows: Bool { dependencies.showsDebugRows }
  public var hasHealth: Bool { dependencies.health != nil }
  public var canRate: Bool { routes.rateApp != nil }
  public var canAddSampleNights: Bool { routes.addSampleNights != nil }

  public func load() async {
    preferences = await dependencies.preferences.load()
    await refreshPermissions()
  }

  /// Writes a change here and, after the writes before it, in the store.
  public func change(_ update: (inout AppPreferences) -> Void) {
    guard var preferences else { return }
    update(&preferences)
    self.preferences = preferences
    let (store, saved) = (dependencies.preferences, preferences)
    enqueue { _ in await store.save(saved) }
  }

  /// A lower limit removes audio, so it asks first.
  public func setStorageLimit(megabytes: Int) {
    if megabytes < (preferences?.storageLimitMB ?? 0) {
      alert = .confirmLowerLimit(megabytes: megabytes)
    } else {
      change { $0.storageLimitMB = megabytes }
    }
  }

  public func confirmLowerLimit() {
    guard case let .confirmLowerLimit(megabytes) = alert else { return }
    alert = nil
    change { $0.storageLimitMB = megabytes }
    enforceLimits(showingReport: false)
  }

  /// On only once Health allows it.
  public func setHealthSync(_ isOn: Bool) {
    guard isOn, let health = dependencies.health else { return change { $0.syncToHealth = false } }
    enqueue { model in
      let granted = await health.requestAuthorization()
      model.change { $0.syncToHealth = granted }
    }
  }

  /// Not asked yet: ask. Denied: the system Settings.
  public func tapMicrophone() {
    tapped(microphone, request: dependencies.requestMicrophone)
  }

  public func tapNotifications() {
    tapped(notifications, request: dependencies.requestNotifications)
  }

  public func askToDeleteAll() {
    alert = .confirmDeleteAll
  }

  public func confirmDeleteAll() {
    alert = nil
    let deleteAll = dependencies.deleteAllData
    enqueue { model in
      do {
        try await deleteAll()
      } catch {
        model.alert = .failed
      }
    }
  }

  /// Debug: runs the cleanup now and reports what it removed.
  public func testCleanup() {
    enforceLimits(showingReport: true)
  }

  public func dismissAlert() {
    alert = nil
  }

  public func openProfile() {
    routes.openProfile()
  }

  public func rateApp() {
    routes.rateApp?()
  }

  public func addSampleNights() {
    routes.addSampleNights?()
  }

  private func enforceLimits(showingReport: Bool) {
    let enforce = dependencies.enforceStorageLimits
    enqueue { model in
      do {
        let report = try await enforce()
        if showingReport { model.alert = .cleanup(report) }
      } catch {
        model.alert = .failed
      }
    }
  }

  private func tapped(_ state: PermissionState, request: @escaping @MainActor () async -> Bool) {
    switch state {
    case .notDetermined:
      enqueue { model in
        _ = await request()
        await model.refreshPermissions()
      }
    case .denied:
      routes.openSystemSettings()
    case .granted:
      break
    }
  }

  private func refreshPermissions() async {
    microphone = dependencies.microphone()
    notifications = await dependencies.notifications()
  }

  /// Runs `work` after the work queued before it, so writes land in order.
  private func enqueue(_ work: @escaping @MainActor (SettingsViewModel) async -> Void) {
    let previous = working
    working = Task { [weak self] in
      await previous?.value
      guard let self else { return }
      await work(self)
    }
  }
}
