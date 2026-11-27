import Foundation

/// Where `AppPreferences` live. Implemented by `SleepPersistenceAdapter` over
/// the shared `PreferencesDefaults`.
public protocol PreferencesStorePort: Sendable {
  func load() async -> AppPreferences
  func save(_ preferences: AppPreferences) async
}
