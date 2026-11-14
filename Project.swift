import ProjectDescription
import ProjectDescriptionHelpers

/// One app target per brand, all generated from `Brand.all`.
/// Adding a brand: an entry in `Brand.all` and a folder in `Apps/`.
let project = Project(
  name: "SleepGuardUIKitWay",
  options: .options(
    automaticSchemesOptions: .enabled(codeCoverageEnabled: true),
    developmentRegion: "en"),
  targets: Brand.all.map(Target.app))
