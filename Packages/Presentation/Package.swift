// swift-tools-version: 6.2
import PackageDescription

/// The UIKit ↔ SwiftUI bridge: the one hosting controller, screen chrome, and
/// the `Navigator` that coordinators drive. Knows nothing about the domain,
/// features or DI. Gains `SleepGuardDesignKit` in F1-T5.
let package = Package(
  name: "Presentation",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "ScreenKit", targets: ["ScreenKit"]),
  ],
  targets: [
    .target(
      name: "ScreenKit",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
