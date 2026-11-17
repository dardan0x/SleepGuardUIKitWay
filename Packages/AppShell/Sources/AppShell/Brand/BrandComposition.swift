import SleepDomain
import SleepGuardDesignKit

/// What a brand target supplies to the shell. Each brand implements it in its
/// own `Apps/<Brand>/Sources/Brand.swift`; a brand that misses a requirement
/// does not compile.
///
/// Requirements are added when the shell first needs something that differs
/// per brand. A capability that needs a framework only some brands link
/// (HealthKit) arrives as a port the brand builds, or `nil`.
public nonisolated protocol BrandComposition: Sendable {
  var configuration: BrandConfiguration { get }
}

/// The runtime differences between brands. Build-time identity (bundle id,
/// display name, URL scheme, app group) lives in the Tuist brand list and
/// reaches the app through Info.plist, so it isn't repeated here.
public nonisolated struct BrandConfiguration: Sendable {
  public var theme: Theme
  /// The tab bar, in order.
  public var tabs: [AppTab]
  /// Apple Health, from `SleepHealth` in brands that link it. `nil`: no
  /// Health rows in Settings, and nights aren't written there.
  public var health: (any HealthAccess)?
  /// The App Store id, once the brand is published: Settings shows
  /// "Rate on App Store" only then.
  public var appStoreID: String?
  /// The Snore Interrupter: a melody when snoring is detected, with its
  /// prestart row and bedside controls. Every brand links the audio it
  /// needs, so this is a value, not a port.
  public var snoreInterrupter: Bool

  /// Every value is stated by each brand: a capability can't be forgotten.
  public init(theme: Theme, tabs: [AppTab], health: (any HealthAccess)?, appStoreID: String?, snoreInterrupter: Bool) {
    precondition(!tabs.isEmpty, "A brand needs at least one tab")
    self.theme = theme
    self.tabs = tabs
    self.health = health
    self.appStoreID = appStoreID
    self.snoreInterrupter = snoreInterrupter
  }
}

public nonisolated enum AppTab: String, CaseIterable, Sendable {
  case statistics
  case history
  case settings
  case learn
}
