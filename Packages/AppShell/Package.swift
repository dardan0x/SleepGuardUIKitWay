// swift-tools-version: 6.2
import PackageDescription

/// The composition root below the app targets: UIKit lifecycle, coordinators,
/// composers and the Factory container. The only package that imports
/// Factory. It does not depend on `SleepHealth`: brands that use HealthKit
/// link it themselves.
let package = Package(
  name: "AppShell",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "AppShell", targets: ["AppShell"]),
    // Navigator spy and a test brand, for shell tests.
    .library(name: "AppShellTestSupport", targets: ["AppShellTestSupport"]),
  ],
  dependencies: [
    .package(path: "../Core"),
    .package(path: "../Adapters"),
    .package(path: "../Presentation"),
    .package(path: "../Features"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.9.0"),
    .package(url: "https://github.com/hmlongco/Factory", exact: "3.5.2"),
  ],
  targets: [
    .target(
      name: "AppShell",
      dependencies: [
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepPersistence", package: "Adapters"),
        .product(name: "SleepAudio", package: "Adapters"),
        .product(name: "ScreenKit", package: "Presentation"),
        .product(name: "HistoryFeature", package: "Features"),
        .product(name: "SessionDetailFeature", package: "Features"),
        .product(name: "StatisticsFeature", package: "Features"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .target(
      name: "AppShellTestSupport",
      dependencies: [
        "AppShell",
        .product(name: "ScreenKit", package: "Presentation"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .testTarget(
      name: "AppShellTests",
      dependencies: [
        "AppShell",
        "AppShellTestSupport",
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepDomainTestSupport", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "ScreenKit", package: "Presentation"),
        .product(name: "HistoryFeature", package: "Features"),
        .product(name: "SessionDetailFeature", package: "Features"),
        .product(name: "StatisticsFeature", package: "Features"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
        .product(name: "FactoryKit", package: "Factory"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
