import SleepCore
import SleepDomain

// What the Settings screens need and where they go, built by the shell.

/// A system permission, as the shell reads it.
public enum PermissionState: Sendable, Equatable {
  case granted
  case denied
  case notDetermined
}

public struct SettingsDependencies {
  public var preferences: any PreferencesStore
  /// Apple Health, when the brand has it: its Settings rows depend on it.
  public var health: (any HealthAccess)?
  public var enforceStorageLimits: EnforceStorageLimits
  public var deleteAllData: DeleteAllData
  /// "1.4.0".
  public var version: String
  public var microphone: @MainActor () -> PermissionState
  /// Asks for the microphone. `true` when granted.
  public var requestMicrophone: @MainActor () async -> Bool
  public var notifications: @MainActor () async -> PermissionState
  public var requestNotifications: @MainActor () async -> Bool
  /// Debug builds: keep raw audio, test the cleanup.
  public var showsDebugRows: Bool

  public init(
    preferences: any PreferencesStore,
    health: (any HealthAccess)?,
    enforceStorageLimits: EnforceStorageLimits,
    deleteAllData: DeleteAllData,
    version: String,
    microphone: @escaping @MainActor () -> PermissionState,
    requestMicrophone: @escaping @MainActor () async -> Bool,
    notifications: @escaping @MainActor () async -> PermissionState,
    requestNotifications: @escaping @MainActor () async -> Bool,
    showsDebugRows: Bool)
  {
    self.preferences = preferences
    self.health = health
    self.enforceStorageLimits = enforceStorageLimits
    self.deleteAllData = deleteAllData
    self.version = version
    self.microphone = microphone
    self.requestMicrophone = requestMicrophone
    self.notifications = notifications
    self.requestNotifications = requestNotifications
    self.showsDebugRows = showsDebugRows
  }
}

public struct SettingsRoutes {
  public var openProfile: @MainActor () -> Void
  /// This app's page in the system Settings (a denied permission).
  public var openSystemSettings: @MainActor () -> Void
  /// The App Store review page; `nil` until the brand has one.
  public var rateApp: (@MainActor () -> Void)?
  /// Debug builds: saves the sample nights again.
  public var addSampleNights: (@MainActor () -> Void)?

  public init(
    openProfile: @escaping @MainActor () -> Void,
    openSystemSettings: @escaping @MainActor () -> Void,
    rateApp: (@MainActor () -> Void)?,
    addSampleNights: (@MainActor () -> Void)?)
  {
    self.openProfile = openProfile
    self.openSystemSettings = openSystemSettings
    self.rateApp = rateApp
    self.addSampleNights = addSampleNights
  }
}

public struct ProfileEditorDependencies {
  public var profiles: any ProfileStore
  public var preferences: any PreferencesStore

  public init(profiles: any ProfileStore, preferences: any PreferencesStore) {
    self.profiles = profiles
    self.preferences = preferences
  }
}

public struct ProfileEditorRoutes {
  public var close: @MainActor () -> Void

  public init(close: @escaping @MainActor () -> Void) {
    self.close = close
  }
}
