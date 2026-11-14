import SleepGuardDesignKit

/// What a brand target supplies to the shell. Each brand implements it in its
/// own `Apps/<Brand>/Sources/Brand.swift`; a brand that misses a requirement
/// does not compile.
///
/// Requirements are added when the shell first needs something that differs
/// per brand (for example a `SleepStagePort` factory in F8, a `NoOp` one in Lite).
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

  public init(theme: Theme, tabs: [AppTab]) {
    precondition(!tabs.isEmpty, "A brand needs at least one tab")
    self.theme = theme
    self.tabs = tabs
  }
}

public nonisolated enum AppTab: String, CaseIterable, Sendable {
  case statistics
  case history
  case settings
  case learn
}
