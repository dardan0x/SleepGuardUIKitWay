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
        .product(name: "FactoryKit", package: "Factory"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .target(
      name: "AppShellTestSupport",
      dependencies: ["AppShell"],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
