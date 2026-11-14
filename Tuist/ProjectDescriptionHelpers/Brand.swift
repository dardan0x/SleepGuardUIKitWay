import ProjectDescription

/// Everything that makes one app target a brand at build time.
///
/// A brand is this entry plus its folder `Apps/<name>/` (asset catalog and
/// entitlements; later its `Brand.swift`). Runtime differences (theme, tabs,
/// capabilities) live in that `Brand.swift`, not here.
public struct Brand: Sendable {
  /// Target, scheme and folder name.
  public let name: String
  public let displayName: String
  public let bundleId: String
  /// Deep-link scheme (`<urlScheme>://…`).
  public let urlScheme: String

  public var appGroup: String {
    "group.\(bundleId)"
  }
}

public extension Brand {
  static let all: [Brand] = [sleepGuard, sleepGuardLite, nocturne]

  static let sleepGuard = Brand(
    name: "SleepGuard",
    displayName: "SleepGuard",
    bundleId: "com.dardan.sleepguardway.sleepguard",
    urlScheme: "sleepguardway")

  static let sleepGuardLite = Brand(
    name: "SleepGuardLite",
    displayName: "SleepGuard Lite",
    bundleId: "com.dardan.sleepguardway.lite",
    urlScheme: "sleepguardlite")

  static let nocturne = Brand(
    name: "Nocturne",
    displayName: "Nocturne",
    bundleId: "com.dardan.sleepguardway.nocturne",
    urlScheme: "nocturne")
}
