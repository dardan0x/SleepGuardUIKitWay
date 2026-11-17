import Foundation
import SleepCore

/// What the person chose in Settings, with SleepGuard's defaults. One value,
/// read whole and written whole through `PreferencesStore`.
public struct AppPreferences: Equatable, Sendable {
  public var sensitivity: DetectionSensitivity = .medium
  public var detectSleepTalking = false
  /// Debug builds: keep the night's full audio and its sample log.
  public var preserveRawAudio = false
  /// One of `RecordingDelay.options`.
  public var recordingDelayMinutes = 0
  public var limitStorage = true
  public var storageLimitMB = StorageLimits.defaultMegabytes
  public var limitDays = true
  public var maxDays = StorageLimits.defaultDays
  /// Write each saved night to Apple Health (brands with HealthKit).
  public var syncToHealth = false
  public var briefingEnabled = true
  public var hasCompletedProfile = false

  public init() {}

  /// The limits as `StoragePlan` takes them: `nil` when off.
  public var maxDaysLimit: Int? { limitDays ? maxDays : nil }
  public var maxMegabytesLimit: Int? { limitStorage ? storageLimitMB : nil }
}

/// Where `AppPreferences` live. Implemented by `SleepPersistence` over
/// `UserDefaults`.
public protocol PreferencesStore: Sendable {
  func load() async -> AppPreferences
  func save(_ preferences: AppPreferences) async
}
