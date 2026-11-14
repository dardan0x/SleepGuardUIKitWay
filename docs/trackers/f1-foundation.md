# F1 — Foundation

> Updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P0 |
| **Milestone** | M1 |
| **Blocked By** | — |
| **Started** | 2026-11-14 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

Three branded apps build from one codebase and launch into an empty, themed tab shell. Every module exists with its boundaries enforced, and CI proves it. No product features yet.

## Tasks

| ID | Task | Type | Status | Depends On | Module | Started | Completed |
|----|------|------|--------|------------|--------|---------|-----------|
| F1-T1 | Repo docs and agent setup | Docs | Done | — | — | 2026-11-14 | 2026-11-14 |
| F1-T2 | Tuist project; three brand app targets that launch | Infra | Done | — | Apps, Tuist | 2026-11-14 | 2026-11-14 |
| F1-T3 | Package skeletons with Swift 6 settings | Infra | Done | F1-T2 | Packages | 2026-11-14 | 2026-11-14 |
| F1-T4 | `SleepGuardDesignKit`: `Theme`, environment key, primitive components | UI | Done | — | Shared repo | 2026-11-14 | 2026-11-14 |
| F1-T5 | `ScreenKit`: `HostingScreen`, `ScreenChrome`, `Navigator` | UI | Done | F1-T3, F1-T4 | ScreenKit | 2026-11-14 | 2026-11-14 |
| F1-T6 | `AppShell`: `BrandComposition`, bootstrap, container, `AppCoordinator`, tab shell | Shell | Backlog | F1-T5 | AppShell | — | — |
| F1-T7 | Three brands: configuration, theme, capabilities, assets; bootstrap test | Brand | Backlog | F1-T6 | Apps, AppShell | — | — |
| F1-T8 | Scripts and CI: test runner, layering, view size, format, PR workflow | CI | Backlog | F1-T3 | scripts, .github | — | — |

## Task Details

### F1-T1 — Repo docs and agent setup

**Acceptance Criteria:**
- [x] `AGENTS.md` and `CLAUDE.md` with this project's rules
- [x] `docs/architecture/` notes for the agreed design
- [x] ADRs 0001–0004
- [x] Roadmap, feature tracker, per-feature trackers, templates
- [x] Workflow doc and session log convention

### F1-T2 — Tuist project and brand targets

| Field | Value |
|-------|-------|
| Arch Ref | `brands.md`, `modules.md` |

**Acceptance Criteria:**
- [x] `Project.swift` builds app targets from `Brand.all` in `Tuist/ProjectDescriptionHelpers`
- [x] `SleepGuard`, `SleepGuardLite`, `Nocturne` each have their own bundle id, display name, icon, launch colour, entitlements
- [x] Swift 6 language mode on all three (`SWIFT_VERSION` 6.0, complete checking, `MainActor` default isolation)
- [x] `tuist generate` succeeds; each scheme builds and launches on the pinned simulator
- [x] Generated project and workspace are git-ignored

**Notes:**
- Tuist 4.55.5. No per-brand xcconfig: the brand list entry holds the build-time identity, so an xcconfig would only duplicate it. Docs updated.
- Entitlements checked in the build output: SleepGuard and Nocturne have HealthKit + their app group; Lite only its app group.
- Icons are generated placeholders (accent circle on the brand background).
- Root screen is a temporary `PlaceholderViewController` showing the display name in the brand accent; it goes in F1-T6.
- The build signed with the team Xcode found automatically (`application-identifier` has a team prefix). No team is set in the project; device builds will need one.

### F1-T3 — Package skeletons

| Field | Value |
|-------|-------|
| Arch Ref | `modules.md`, `concurrency.md` |

**Acceptance Criteria:**
- [x] `Core`, `Adapters`, `Presentation`, `AppShell` packages with the products in `modules.md`; `Features` deferred to F3-T1 (no screen to put in it yet)
- [x] Manifests express the import table. A forbidden import fails to compile **when the package builds standalone** (`import ScreenKit` in `SleepDomain`; `import FactoryKit` in `SleepPersistence`), but the second one **compiled inside the app workspace**. Standalone package builds and an import check move into F1-T8.
- [x] Swift 6 mode everywhere; `MainActor` default isolation only in `ScreenKit` and `AppShell`
- [x] `SleepDomain` builds and tests on macOS with `swift test` (1 wiring test against `SleepCore` 0.1.0)
- [x] `SleepGuardShared` only in `Core` and `Adapters`; Factory only in `AppShell`
- [x] Dev override: `tuist generate` resolves `../SleepGuardShared` locally; `TUIST_SHARED_RELEASE=1` resolves GitHub 0.1.0 (both checked)
- [x] All three brands build and launch with the root screen served by `AppShell`

**Notes:**
- Placeholder sources (one comment-only file per module) say which task fills them.
- `exact:` versions for `SleepGuardShared` and Factory: the generated workspace's lockfile isn't committed, so the manifests are the pins.
- `PlaceholderViewController` moved from the app target into `AppShell`; still deleted in F1-T6.

### F1-T4 — Design kit

| Field | Value |
|-------|-------|
| Arch Ref | `brands.md` |

**Acceptance Criteria:**
- [x] `SleepGuardDesignKit` product in the shared repo: `Theme` (`Palette`, `Typography`, `Radii`) as a `Sendable` value, `@Environment(\.theme)` defaulting to `Theme.sleepGuard`
- [x] Default palette equals SleepGuard's `Theme.swift` tokens
- [x] Components with no domain types: `StatCard`, `SleepScoreGauge`, `MiniBarChart`, `AudioLevelMeter`, `SheetHandle`, `SheetNavHeader`, `ScaleButtonStyle`, `RecordingActionButton`, `StartRecordingButton`, `StopRecordingButton`
- [x] Re-exports `SleepStrings`; no dependency on `Models`, Factory or `SleepCore`
- [x] Renders in two themes: render tests draw a gallery of every component with `Theme.sleepGuard` and a deliberately different theme, and check the renders differ; both images reviewed by eye

**Notes:**
- Ported from SleepGuard's `DesignSystem` with `@Injected(\.theme)` → `@Environment(\.theme)`. The hard-coded hex colours in the recording buttons and sheet handle now use tokens (`destructive`, `bgCard`, `textTertiary`), which is what lets a brand restyle them.
- Text fonts go through `theme.typography.font(size:weight:)`; large numbers stay `.rounded` in every theme.
- **Token mismatch in SleepGuard:** its `CLAUDE.md` lists `bg-card` = `#2C2C2E`, its `Theme.swift` uses `#22232B` (as `surface2`). The kit takes the code's value. Needs a decision against `designs/SleepGuard.pen`.
- Not verified against the `.pen` design file in this task: the components are ported unchanged in layout, so they match SleepGuard as it ships today.
- Released as `0.2.0` only after the shared PR is merged; this app adopts it in F1-T5.
- Unchanged in SleepGuard: it doesn't use the kit until F6. Its dev workspace still builds against the shared branch.

### F1-T5 — ScreenKit

| Field | Value |
|-------|-------|
| Arch Ref | `composition.md`, `navigation.md` |

**Acceptance Criteria:**
- [x] `HostingScreen<Content>` injects the theme into the SwiftUI environment, paints the theme background, applies `ScreenChrome` (title, large title, hidden bar, trailing icon items with required accessibility labels)
- [x] `Navigator` protocol with `NavigationControllerNavigator`: every operation waits for a running transition to finish instead of being dropped
- [ ] Child-containment helper: **deferred**, no planned screen embeds SwiftUI inside UIKit content; add it with the first one
- [x] Tests (11, simulator): chrome on the navigation item, theme reaches SwiftUI content (probe view), background, hidden bar; set root / push / pop / pop to root; sheet and full-screen configuration; dismiss with nothing presented
- [ ] Real present/dismiss (incl. the in-flight wait) checked inside the app in F1-T6

**Notes:**
- Packages now use shared `0.2.0` (`Core`, `Adapters`, `Presentation`); domain test passes against it.
- **Package tests can't present.** They run without a host app, so a `UIWindow` has no scene and UIKit never finishes a presentation; two such tests hung the run (stopped). They were replaced by tests of the presentation configuration; actual presenting is verified in the app (F1-T6), where there is a scene.
- Test runs now use xcodebuild's per-test time limit, so a hang fails fast instead of blocking.
- `.package.resolved` (Tuist's root copy of the workspace lockfile) is git-ignored: it changes with the generate mode.

### F1-T6 — AppShell

| Field | Value |
|-------|-------|
| Arch Ref | `dependencies.md`, `navigation.md` |

**Acceptance Criteria:**
- [ ] `BrandComposition`, `BrandConfiguration`, `Capabilities`
- [ ] `AppShell.bootstrap(brand:)` registers the brand; container factories derive from it
- [ ] `AppCoordinator` and `MainTabCoordinator` build tabs from `BrandConfiguration.tabs` with placeholder screens
- [ ] Theme applied to navigation and tab bar appearance
- [ ] `AppShellTestSupport`: `NavigatorSpy`, `TestBrand`
- [ ] In the running app: present and dismiss a sheet through `NavigationControllerNavigator`, including one issued during another transition (carried over from F1-T5)
- [ ] Tests: tabs match the configuration; a route closure produces the expected navigator call

### F1-T7 — Three brands

| Field | Value |
|-------|-------|
| Arch Ref | `brands.md` |

**Acceptance Criteria:**
- [ ] Each brand's `Brand.swift` implements `BrandComposition`
- [ ] SleepGuard Lite: three tabs, no sleep stages, no Snore Interrupter, no Learn; does not link `SleepHealth`
- [ ] Nocturne: its own palette and typography, History tab first
- [ ] Test: every brand bootstraps and resolves every registration
- [ ] Run all three; palette and tab set visibly differ

### F1-T8 — Scripts and CI

| Field | Value |
|-------|-------|
| Arch Ref | `testing.md`, `rules.md` |

**Acceptance Criteria:**
- [ ] `scripts/run-tests.sh` runs both lanes with xcodebuild's per-test time limit (`-test-timeouts-enabled YES`) and builds every package standalone (the app workspace hides undeclared imports; see F1-T3)
- [ ] `scripts/check-layering.py`: forbidden imports, Factory outside `AppShell`, `.shared`, concurrency escape hatches, SwiftUI navigation APIs in features, `print(`
- [ ] `scripts/check-view-size.py`: 200-line limit with an allowlist that can only shrink
- [ ] Hardcoded-string check
- [ ] GitHub Actions on pull request: `TUIST_SHARED_RELEASE=1 tuist generate`, build three schemes, tests, checks, SwiftFormat lint
- [ ] Each check is shown failing on a deliberate violation, then passing
