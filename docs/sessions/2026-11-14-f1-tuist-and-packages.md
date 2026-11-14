---
date: 2026-11-14
feature: F1
branch: feature/f1/t3-package-skeletons
title: Tuist project with three brands; package skeletons on the shared release
---

### Completed
- F0-T3 to F0-T5 (other repos): `SleepGuardShared` public with tag `0.1.0` and CI; SleepGuard consumes it by version with a dev workspace.
- F1-T2: Tuist 4.55.5 project. `SleepGuard`, `SleepGuardLite`, `Nocturne` generated from `Brand.all`; each with its own bundle id, display name, URL scheme, app group, placeholder icon, launch and accent colours, entitlements (Lite has no HealthKit). All three build and launch.
- F1-T3: `Core` (`SleepDomain`, `SleepDomainTestSupport`), `Adapters` (`SleepPersistence`, `SleepAudio`, `SleepHealth`), `Presentation` (`ScreenKit`), `AppShell` (`AppShell`, `AppShellTestSupport`). The apps link `AppShell`, which serves the placeholder root screen.

### Technical Details
- No per-brand xcconfig: the `Brand` list entry is the build-time identity; `Target.app(_:)` gives every brand the same target shape.
- Packages pin `SleepGuardShared` and Factory with `exact:` because Tuist's workspace (and its lockfile) is generated and not committed.
- `tuist generate` adds `../SleepGuardShared` as a local package (local edits win); `TUIST_SHARED_RELEASE=1 tuist generate` uses GitHub 0.1.0. Both resolutions checked.
- **Finding:** an undeclared `import FactoryKit` in `SleepPersistence` compiles inside the app workspace (Xcode exposes modules built for other targets) and fails when the package builds on its own. `import ScreenKit` in `SleepDomain` fails under `swift build`. So manifest-based layering only holds for standalone package builds; F1-T8 adds them to CI. SleepGuard has the same leak.

### Files Changed
| File | What Changed |
|------|--------------|
| `Tuist.swift`, `Project.swift`, `Tuist/ProjectDescriptionHelpers/{Brand,Target+Brand}.swift` | Project generation, brand list, target shape, shared override |
| `Apps/Shared/Sources/{AppDelegate,SceneDelegate}.swift` | UIKit lifecycle; root from `AppShell` |
| `Apps/{SleepGuard,SleepGuardLite,Nocturne}/` | Asset catalogs (icon, two colours), entitlements |
| `Packages/{Core,Adapters,Presentation,AppShell}/Package.swift` | Module boundaries, Swift 6 settings, isolation |
| `Packages/*/Sources/*/…swift` | One placeholder per module; `AppShell.makeRootViewController()`; moved `PlaceholderViewController` |
| `Packages/Core/Tests/SleepDomainTests/SharedCoreWiringTests.swift` | Domain reaches `SleepCore` |
| `AGENTS.md`, `CLAUDE.md`, `docs/architecture/{brands,modules}.md`, `docs/adr/0003…`, `README.md` | No xcconfig; generate modes; the import-leak caveat |
| `docs/FeatureTracker.md`, `docs/Roadmap.md`, `docs/trackers/f0…`, `f1…` | Status |

### Architecture Decisions
- Features package deferred to F3-T1: there is no screen to put in it yet.

### Build Status
- **BUILD SUCCEEDED** for `SleepGuard`, `SleepGuardLite`, `Nocturne` (simulator, local-override mode). Nocturne launched after T3.
- `swift test` in `Packages/Core`: 1 test passed.
- SwiftFormat lint: clean.
- Not verified: a release-mode (`TUIST_SHARED_RELEASE=1`) full build (resolution only); device builds (no team set).

### Suggested Branch
`feature/f1/t3-package-skeletons`

### Suggested Commit
`F1-T3 — Package skeletons with Swift 6 settings`

### Next Session
- F1-T4 (done in the same sitting, see `2026-11-14-f1-t4-design-kit.md`).

### Open Questions
- None. (`docs/architecture/` and `docs/CODING_WORKFLOW.md` are local-only by the owner's `.gitignore`, like SleepGuard's.)
