// swift-tools-version: 6.2
import PackageDescription

/// The domain. Foundation and the shared `SleepCore` only: no UI, no
/// persistence, no DI, no brands. macOS is listed so its tests run with
/// `swift test`, in seconds, without a simulator.
let package = Package(
  name: "Core",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "SleepDomain", targets: ["SleepDomain"]),
    // Fakes for every port. Only test targets and previews depend on it.
    .library(name: "SleepDomainTestSupport", targets: ["SleepDomainTestSupport"]),
  ],
  dependencies: [
    .package(url: "https://github.com/dardan0x/SleepGuardShared.git", exact: "0.10.0"),
  ],
  targets: [
    .target(
      name: "SleepDomain",
      dependencies: [.product(name: "SleepCore", package: "SleepGuardShared")],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .target(
      name: "SleepDomainTestSupport",
      dependencies: ["SleepDomain", .product(name: "SleepCore", package: "SleepGuardShared")],
      swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(
      name: "SleepDomainTests",
      dependencies: [
        "SleepDomain",
        "SleepDomainTestSupport",
        .product(name: "SleepCore", package: "SleepGuardShared"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]),
  ])
