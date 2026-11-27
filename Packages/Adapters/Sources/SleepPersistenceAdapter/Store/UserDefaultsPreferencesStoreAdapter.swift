import Foundation
import SleepCore
import SleepDomain
import SleepSettings

/// `PreferencesStorePort` over the shared `PreferencesDefaults` (SleepGuardShared):
/// the keys, defaults and validity rules SleepGuard's `UserPreferences` uses
/// too. This adapter adds the port's shape: the whole value, `async`.
struct UserDefaultsPreferencesStoreAdapter: PreferencesStorePort {
  private let settings: PreferencesDefaults

  /// `nil`: the app's standard defaults.
  init(suiteName: String?) {
    settings = PreferencesDefaults(suiteName: suiteName)
  }

  func load() async -> AppPreferences {
    settings.load()
  }

  func save(_ preferences: AppPreferences) async {
    settings.save(preferences)
  }
}
