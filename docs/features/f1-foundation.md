# F1 — Foundation

Three branded apps build from one codebase and launch into a themed tab shell. Every module exists with its boundaries enforced, and CI checks it on every pull request. No product features yet: each tab shows a placeholder flow.

## Files

| File | Purpose |
|------|---------|
| `Project.swift`, `Tuist.swift`, `Tuist/ProjectDescriptionHelpers/Brand.swift` | Brand list (identity, `usesHealthKit`) → app targets and hosted test targets; shared package local or released (`TUIST_SHARED_RELEASE`) |
| `Tuist/ProjectDescriptionHelpers/Target+Brand.swift` | One target shape for every brand; hosted tests per brand |
| `mise.toml` | Tuist version |
| `Apps/Shared/Sources/{AppDelegate,SceneDelegate}.swift` | UIKit lifecycle; bootstraps the shell with `appBrand` |
| `Apps/<Brand>/Sources/Brand.swift` | The brand's theme and tabs |
| `Apps/<Brand>/Resources/Assets.xcassets`, `<Brand>.entitlements` | Icon, launch and accent colours; app group, HealthKit where used |
| `Apps/HostedTests/{NavigatorInAppTests,BrandBootstrapTests}.swift` | Tests that need a running app |
| `Packages/Core` | `SleepDomain` (empty until F2), test support, domain tests on macOS |
| `Packages/Adapters` | `SleepPersistence`, `SleepAudio`, `SleepHealth` (empty until their features) |
| `Packages/Presentation/Sources/ScreenKit/{HostingScreen,ScreenChrome,Navigator}.swift` | The UIKit ↔ SwiftUI bridge |
| `Packages/AppShell/Sources/AppShell/Brand/BrandComposition.swift` | Brand contract |
| `Packages/AppShell/Sources/AppShell/{AppShell,Container+AppShell}.swift` | Bootstrap and container |
| `Packages/AppShell/Sources/AppShell/Coordinators/{AppCoordinator,MainTabCoordinator,Appearance}.swift` | Window, tabs, themed bars |
| `Packages/AppShell/Sources/AppShell/Placeholder/*` | Temporary per-tab flow and screen |
| `Packages/AppShell/Sources/AppShellTestSupport/{NavigatorSpy,TestBrand}.swift` | Test doubles |
| `../SleepGuardShared/Sources/SleepGuardDesignKit/**` | Theme value and primitive components (F1-T4, shared repo) |
| `scripts/{run-tests.sh,check-layering.py,check-view-size.py,check-hardcoded-strings.py,bump-shared.sh}` | Tests and checks |
| `.github/workflows/ci.yml` | Pull request CI |

## Routes

| Intent | Emitted by | Handled by |
|--------|-----------|-----------|
| `PlaceholderRoutes.showDetails` | `PlaceholderScreen` ("Continue") | `PlaceholderFlow`: presents a sheet (medium/large) above whatever is on top |
| `PlaceholderRoutes.close` | Presented `PlaceholderScreen` ("Close") | `PlaceholderFlow`: dismisses the top presentation |

Temporary: each tab's routes are replaced by its feature's.

## State

| State | Where | Lifetime |
|-------|-------|----------|
| Brand | `Container.shared.brand` (registered once in `AppShell.bootstrap`) | App |
| Theme | Derived from the brand; SwiftUI environment via `HostingScreen`; bar appearances | App |
| Tab flows | `MainTabCoordinator.flows` | App |
| Screen state | SwiftUI `@State` in each hosted screen | The hosting controller |

## Edge cases

- **Navigation during a transition:** the navigator waits for the running transition to finish, then performs the operation; nothing is dropped (in-app test).
- **Nothing presented on dismiss:** no-op.
- **A brand with no tabs:** rejected by `BrandConfiguration`'s precondition.
- **Shell used before bootstrap:** the brand factory's precondition names `AppShell.bootstrap(brand:)`.
- **Undeclared imports:** compile inside the app workspace; caught by the standalone package lane (isolated derived data) and `check-layering.py`.
- **Package tests can't present:** no window scene; presentation is tested in the hosted targets.

## Tasks completed

F1-T1 docs and agent setup · F1-T2 Tuist project and brand targets · F1-T3 package skeletons · F1-T4 design kit (shared repo) · F1-T5 ScreenKit · F1-T6 AppShell · F1-T7 three brands · F1-T8 scripts and CI.
