// swift-tools-version: 6.2
import PackageDescription

/// Adapters implement domain ports with one Apple framework each, so a brand
/// can leave one out (SleepGuard Lite doesn't link `SleepHealthAdapter`). They depend
/// on the domain and never on each other, the UI, or DI.
let package = Package(
  name: "Adapters",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "SleepPersistenceAdapter", targets: ["SleepPersistenceAdapter"]),
    .library(name: "SleepAudioAdapter", targets: ["SleepAudioAdapter"]),
    .library(name: "SleepHealthAdapter", targets: ["SleepHealthAdapter"]),
  ],
  dependencies: [
    .package(path: "../Core"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.37.0"),
  ],
  targets: [
    // SwiftData, files, UserDefaults.
    .target(
      name: "SleepPersistenceAdapter",
      dependencies: [
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepLogging", package: "SleepGuardShared"),
        .product(name: "SleepFiles", package: "SleepGuardShared"),
        .product(name: "SleepSettings", package: "SleepGuardShared"),
        .product(name: "SleepStore", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    // The shared SleepAudioKit behind the audio ports; the Snore Interrupter's sounds.
    .target(
      name: "SleepAudioAdapter",
      dependencies: [
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepLogging", package: "SleepGuardShared"),
        .product(name: "SleepMelodies", package: "SleepGuardShared"),
        .product(name: "SleepAudioKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepPersistenceAdapterTests",
      dependencies: [
        "SleepPersistenceAdapter",
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepDomainTestSupport", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepFiles", package: "SleepGuardShared"),
        .product(name: "SleepStore", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepAudioAdapterTests",
      dependencies: [
        "SleepAudioAdapter",
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepDomainTestSupport", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    // HealthKit.
    .target(
      name: "SleepHealthAdapter",
      dependencies: [
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepLogging", package: "SleepGuardShared"),
        .product(name: "SleepHealthKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),

    .testTarget(
      name: "SleepHealthAdapterTests",
      dependencies: [
        "SleepHealthAdapter",
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepHealthKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),
  ])
