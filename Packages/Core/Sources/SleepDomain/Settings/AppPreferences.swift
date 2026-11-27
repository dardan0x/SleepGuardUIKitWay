import Foundation
import SleepCore

/// What the person chose in Settings: SleepCore's `SleepPreferences`, the
/// value SleepGuard uses too (same fields, same defaults). One value, read
/// whole and written whole through `PreferencesStore`.
public typealias AppPreferences = SleepPreferences

/// Where `AppPreferences` live. Implemented by `SleepPersistence` over
/// the shared `PreferencesDefaults`.
public protocol PreferencesStore: Sendable {
  func load() async -> AppPreferences
  func save(_ preferences: AppPreferences) async
}
