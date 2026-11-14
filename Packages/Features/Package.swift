// swift-tools-version: 6.2
import PackageDescription

/// Screens. One module per screen family; each exposes its screen view, a
/// `Dependencies` struct and a `Routes` struct, nothing else. Features see the
/// domain, the shared core and the design kit; never UIKit, Factory, adapters
/// or each other.
let package = Package(
  name: "Features",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "HistoryFeature", targets: ["HistoryFeature"]),
    .library(name: "SessionDetailFeature", targets: ["SessionDetailFeature"]),
  ],
  dependencies: [
    .package(path: "../Core"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.6.0"),
  ],
  targets: [
    .target(
      name: "HistoryFeature",
      dependencies: [
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .target(
      name: "SessionDetailFeature",
      dependencies: [
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .testTarget(
      name: "SessionDetailFeatureTests",
      dependencies: [
        "SessionDetailFeature",
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepDomainTestSupport", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .testTarget(
      name: "HistoryFeatureTests",
      dependencies: [
        "HistoryFeature",
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepDomainTestSupport", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
