import Foundation
import SleepCore
import SleepDomain

/// `PreferencesStore` over `UserDefaults`, one key per setting (as
/// SleepGuard's `UserPreferences`), so a setting added later reads its
/// default from older installs.
struct UserDefaultsPreferencesStore: PreferencesStore {
  /// `nil`: the app's standard defaults.
  let suiteName: String?

  /// Opened per call: `UserDefaults` isn't `Sendable`, and it is thread-safe
  /// and cached by the system.
  private var defaults: UserDefaults {
    suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
  }

  private enum Key {
    static let sensitivity = "detectionSensitivity"
    static let sleepTalking = "detectSleepTalking"
    static let rawAudio = "preserveRawAudio"
    static let delay = "recordingDelayMinutes"
    static let limitStorage = "limitStorageEnabled"
    static let storageMB = "storageLimitMB"
    static let limitDays = "limitDaysEnabled"
    static let maxDays = "maxDays"
    static let health = "syncToHealthKit"
    static let briefing = "briefingEnabled"
    static let profile = "hasCompletedProfile"
    static let onboarding = "hasCompletedOnboarding"
    static let lastBriefing = "lastBriefingShownDate"
    static let promptDismissals = "profilePromptDismissCount"
    // SleepGuard's names (the mode's key predates the feature's name).
    static let interrupterMode = "soothingMelodyMode"
    static let melody = "selectedMelodyID"
  }

  func load() async -> AppPreferences {
    let defaults = defaults
    var preferences = AppPreferences()
    if let raw = defaults.string(forKey: Key.sensitivity), let sensitivity = DetectionSensitivity(rawValue: raw) {
      preferences.sensitivity = sensitivity
    }
    preferences.detectSleepTalking = bool(Key.sleepTalking) ?? preferences.detectSleepTalking
    preferences.preserveRawAudio = bool(Key.rawAudio) ?? preferences.preserveRawAudio
    preferences.recordingDelayMinutes = RecordingDelay.valid(defaults.integer(forKey: Key.delay))
    preferences.limitStorage = bool(Key.limitStorage) ?? preferences.limitStorage
    preferences.storageLimitMB = int(Key.storageMB) ?? preferences.storageLimitMB
    preferences.limitDays = bool(Key.limitDays) ?? preferences.limitDays
    preferences.maxDays = int(Key.maxDays) ?? preferences.maxDays
    preferences.syncToHealth = bool(Key.health) ?? preferences.syncToHealth
    preferences.briefingEnabled = bool(Key.briefing) ?? preferences.briefingEnabled
    preferences.hasCompletedProfile = bool(Key.profile) ?? preferences.hasCompletedProfile
    preferences.hasCompletedOnboarding = bool(Key.onboarding) ?? preferences.hasCompletedOnboarding
    preferences.lastBriefingShown = defaults.object(forKey: Key.lastBriefing) as? Date
    preferences.profilePromptDismissCount = int(Key.promptDismissals) ?? 0
    preferences.interrupterMode = SnoreInterrupterMode(stored: defaults.string(forKey: Key.interrupterMode))
    preferences.melodyID = int(Key.melody).flatMap { $0 > 0 ? $0 : nil } ?? preferences.melodyID
    return preferences
  }

  func save(_ preferences: AppPreferences) async {
    let defaults = defaults
    defaults.set(preferences.sensitivity.rawValue, forKey: Key.sensitivity)
    defaults.set(preferences.detectSleepTalking, forKey: Key.sleepTalking)
    defaults.set(preferences.preserveRawAudio, forKey: Key.rawAudio)
    defaults.set(preferences.recordingDelayMinutes, forKey: Key.delay)
    defaults.set(preferences.limitStorage, forKey: Key.limitStorage)
    defaults.set(preferences.storageLimitMB, forKey: Key.storageMB)
    defaults.set(preferences.limitDays, forKey: Key.limitDays)
    defaults.set(preferences.maxDays, forKey: Key.maxDays)
    defaults.set(preferences.syncToHealth, forKey: Key.health)
    defaults.set(preferences.briefingEnabled, forKey: Key.briefing)
    defaults.set(preferences.hasCompletedProfile, forKey: Key.profile)
    defaults.set(preferences.hasCompletedOnboarding, forKey: Key.onboarding)
    defaults.set(preferences.lastBriefingShown, forKey: Key.lastBriefing)
    defaults.set(preferences.profilePromptDismissCount, forKey: Key.promptDismissals)
    defaults.set(preferences.interrupterMode.rawValue, forKey: Key.interrupterMode)
    defaults.set(preferences.melodyID, forKey: Key.melody)
  }

  /// `nil` when never written, so the default applies.
  private func bool(_ key: String) -> Bool? {
    defaults.object(forKey: key) as? Bool
  }

  private func int(_ key: String) -> Int? {
    defaults.object(forKey: key) as? Int
  }
}
