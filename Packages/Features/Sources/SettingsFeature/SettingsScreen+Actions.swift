import SleepDomain
import SwiftUI

/// What `SettingsScreen`'s taps do.
extension SettingsScreen {
  func refreshPermissions() async {
    microphone = dependencies.microphone()
    notifications = await dependencies.notifications()
  }

  /// Writes a change, here and in the store.
  func change(_ update: (inout AppPreferences) -> Void) {
    guard var preferences else { return }
    update(&preferences)
    self.preferences = preferences
    let store = dependencies.preferences
    let saved = preferences
    Task { await store.save(saved) }
  }

  func deleteAll() {
    Task {
      do {
        try await dependencies.deleteAllData()
      } catch {
        alert = .failed
      }
    }
  }

  func confirmLowerLimit() {
    guard case let .lowerLimit(megabytes) = alert else { return }
    change { $0.storageLimitMB = megabytes }
    enforceLimits(showingReport: false)
  }

  /// After the new limit is saved: the store is read again first.
  func enforceLimits(showingReport: Bool) {
    let store = dependencies.preferences
    let saved = preferences
    Task {
      if let saved { await store.save(saved) }
      do {
        let report = try await dependencies.enforceStorageLimits()
        if showingReport { alert = .cleanup(report) }
      } catch {
        alert = .failed
      }
    }
  }

  func isShowing(_ matches: @escaping (Alert) -> Bool) -> Binding<Bool> {
    Binding(get: { alert.map(matches) ?? false }, set: { if !$0 { alert = nil } })
  }
}
