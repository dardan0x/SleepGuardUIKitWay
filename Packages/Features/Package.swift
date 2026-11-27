// swift-tools-version: 6.2
import PackageDescription

/// Screens. One module per screen family; each exposes its screen view, a
/// `Dependencies` struct and a `Routes` struct, nothing else. Features see the
/// domain, the shared core and the design kit; a screen whose structure is
/// UIKit (ADR 0007) also sees UIKit and `ScreenKit`. Never Factory, adapters
/// or each other.
///
/// Nothing is re-exported (shared 0.37.0): a target declares every module its
/// files import, the content kit, the design kit (`Theme`, components) and
/// `SleepStrings` (`Strings`) alike.
let package = Package(
  name: "Features",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "HistoryFeature", targets: ["HistoryFeature"]),
    .library(name: "SessionDetailFeature", targets: ["SessionDetailFeature"]),
    .library(name: "StatisticsFeature", targets: ["StatisticsFeature"]),
    .library(name: "RecordingFeature", targets: ["RecordingFeature"]),
    .library(name: "SettingsFeature", targets: ["SettingsFeature"]),
    .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
    .library(name: "LearnFeature", targets: ["LearnFeature"]),
    .library(name: "BriefingFeature", targets: ["BriefingFeature"]),
  ],
  dependencies: [
    .package(path: "../Core"),
    .package(path: "../Presentation"),
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.37.0"),
  ],
  targets: [
    .target(
      name: "HistoryFeature",
      dependencies: [
        .product(name: "ScreenKit", package: "Presentation"),
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepGuardContentKit", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
        .product(name: "SleepStrings", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .target(
      name: "SessionDetailFeature",
      dependencies: [
        .product(name: "ScreenKit", package: "Presentation"),
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepGuardContentKit", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
        .product(name: "SleepStrings", package: "SleepGuardShared"),
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
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .target(
      name: "StatisticsFeature",
      dependencies: [
        .product(name: "ScreenKit", package: "Presentation"),
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepGuardContentKit", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .target(
      name: "SettingsFeature",
      dependencies: [
        .product(name: "ScreenKit", package: "Presentation"),
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepGuardContentKit", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
        .product(name: "SleepStrings", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .target(
      name: "OnboardingFeature",
      dependencies: [
        .product(name: "ScreenKit", package: "Presentation"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepGuardContentKit", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
        .product(name: "SleepStrings", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .target(
      name: "BriefingFeature",
      dependencies: [
        .product(name: "ScreenKit", package: "Presentation"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepGuardContentKit", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .target(
      name: "LearnFeature",
      dependencies: [
        .product(name: "ScreenKit", package: "Presentation"),
        .product(name: "SleepGuardContentKit", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .target(
      name: "RecordingFeature",
      dependencies: [
        .product(name: "ScreenKit", package: "Presentation"),
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
        .product(name: "SleepGuardContentKit", package: "SleepGuardShared"),
        .product(name: "SleepGuardDesignKit", package: "SleepGuardShared"),
        .product(name: "SleepStrings", package: "SleepGuardShared"),
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
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .testTarget(
      name: "SettingsFeatureTests",
      dependencies: [
        "SettingsFeature",
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepDomainTestSupport", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .testTarget(
      name: "OnboardingFeatureTests",
      dependencies: [
        "OnboardingFeature",
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
    .testTarget(
      name: "RecordingFeatureTests",
      dependencies: [
        "RecordingFeature",
        .product(name: "SleepDomain", package: "Core"),
        .product(name: "SleepDomainTestSupport", package: "Core"),
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .defaultIsolation(MainActor.self),
      ]),
  ])
