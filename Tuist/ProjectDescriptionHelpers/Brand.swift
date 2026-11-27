import ProjectDescription

/// Everything that makes one app target a brand at build time.
///
/// A brand is this entry plus its folder `Apps/<name>/` (`Sources/Brand.swift`,
/// asset catalog, entitlements). Runtime differences (theme, tabs) live in that
/// `Brand.swift`; this entry holds what must be decided at build time.
public struct Brand: Sendable {
  /// Target, scheme and folder name.
  public let name: String
  public let displayName: String
  public let bundleId: String
  /// Deep-link scheme (`<urlScheme>://…`).
  public let urlScheme: String
  /// Links `SleepHealthAdapter`. Keep in step with the HealthKit
  /// entitlement in `Apps/<name>/<name>.entitlements`.
  public let usesHealthKit: Bool

  public var appGroup: String {
    "group.\(bundleId)"
  }
}

public extension Brand {
  static let all: [Brand] = [sleepGuard, sleepGuardLite, nocturne, dawn]

  static let sleepGuard = Brand(
    name: "SleepGuard",
    displayName: "SleepGuard",
    bundleId: "com.dardan.sleepguardway.sleepguard",
    urlScheme: "sleepguardway",
    usesHealthKit: true)

  static let sleepGuardLite = Brand(
    name: "SleepGuardLite",
    displayName: "SleepGuard Lite",
    bundleId: "com.dardan.sleepguardway.lite",
    urlScheme: "sleepguardlite",
    usesHealthKit: false)

  static let nocturne = Brand(
    name: "Nocturne",
    displayName: "Nocturne",
    bundleId: "com.dardan.sleepguardway.nocturne",
    urlScheme: "nocturne",
    usesHealthKit: true)

  static let dawn = Brand(
    name: "Dawn",
    displayName: "Dawn",
    bundleId: "com.dardan.sleepguardway.dawn",
    urlScheme: "dawn",
    usesHealthKit: true)
}
