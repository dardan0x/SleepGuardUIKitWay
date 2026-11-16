// swift-tools-version: 6.2
import PackageDescription

/// The UIKit ↔ SwiftUI bridge: the one hosting controller, screen chrome, and
/// the `Navigator` that coordinators drive. Knows nothing about the domain,
/// features or DI.
let package = Package(
  name: "Presentation",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "ScreenKit", targets: ["ScreenKit"]),
  ],
  dependencies: [
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.20.0"),
  ],
  targets: [
    .target(
      name: "ScreenKit",
      dependencies: [.product(name: "SleepGuardDesignKit", package: "SleepGuardShared")],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .testTarget(
      name: "ScreenKitTests",
      dependencies: [
        "ScreenKit",
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
