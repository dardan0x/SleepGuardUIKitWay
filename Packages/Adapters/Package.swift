// swift-tools-version: 6.2
import PackageDescription

/// Adapters implement domain ports with one Apple framework each, so a brand
/// can leave one out (SleepGuard Lite doesn't link `SleepHealth`). They depend
/// on the domain and never on each other, the UI, or DI.
let package = Package(
  name: "Adapters",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "SleepPersistence", targets: ["SleepPersistence"]),
    .library(name: "SleepAudio", targets: ["SleepAudio"]),
    .library(name: "SleepHealth", targets: ["SleepHealth"]),
  ],
  dependencies: [
    .package(path: "../Core"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.23.0"),
  ],
  targets: [
    // SwiftData, files, UserDefaults.
    .target(
      name: "SleepPersistence",
      dependencies: [
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    // AVFoundation, SoundAnalysis, Accelerate.
    .target(
      name: "SleepAudio",
      dependencies: [
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepPersistenceTests",
      dependencies: [
        "SleepPersistence",
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepAudioTests",
      dependencies: [
        "SleepAudio",
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    // HealthKit.
    .target(
      name: "SleepHealth",
      dependencies: [
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),

    .testTarget(
      name: "SleepHealthTests",
      dependencies: [
        "SleepHealth",
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),
  ])
