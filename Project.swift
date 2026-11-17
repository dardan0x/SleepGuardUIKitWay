import ProjectDescription
import ProjectDescriptionHelpers

/// One app target per brand, all generated from `Brand.all`.
/// Adding a brand: an entry in `Brand.all` and a folder in `Apps/`.
///
/// Shared code: packages require a released `SleepGuardShared` (`exact:`).
/// By default the project uses the sibling checkout `../SleepGuardShared` as a
/// local package, which overrides the release, so local edits show up on the
/// next build. CI generates with `TUIST_SHARED_RELEASE=1` to build the pinned
/// release instead. The brand targets import the design kit directly, so the
/// project declares the shared package either way.
let useReleasedShared = Environment.sharedRelease.getBoolean(default: false)

/// Must match the `exact:` version in the package manifests.
let sharedVersion: Version = "0.22.0"

let project = Project(
  name: "SleepGuardUIKitWay",
  options: .options(
    automaticSchemesOptions: .enabled(codeCoverageEnabled: true),
    developmentRegion: "en"),
  packages: [
    .local(path: "Packages/Core"),
    .local(path: "Packages/Adapters"),
    .local(path: "Packages/Presentation"),
    .local(path: "Packages/Features"),
    .local(path: "Packages/AppShell"),
    useReleasedShared
      ? .remote(url: "https://github.com/dardan0x/SleepGuardShared.git", requirement: .exact(sharedVersion))
      : .local(path: "../SleepGuardShared"),
  ],
  targets: Brand.all.map(Target.app) + Brand.all.map(Target.hostedTests(in:)))
