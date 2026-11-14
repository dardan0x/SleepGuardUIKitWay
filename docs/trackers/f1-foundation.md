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
| F1-T2 | Tuist project; three brand app targets that launch | Infra | Backlog | — | Apps, Tuist | — | — |
| F1-T3 | Package skeletons with Swift 6 settings | Infra | Backlog | F1-T2 | Packages | — | — |
| F1-T4 | `SleepGuardDesignKit`: `Theme`, environment key, primitive components | UI | Backlog | — | Shared repo | — | — |
| F1-T5 | `ScreenKit`: `HostingScreen`, `ScreenChrome`, `Navigator` | UI | Backlog | F1-T3, F1-T4 | ScreenKit | — | — |
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
- [ ] `Project.swift` builds app targets from one brand list in `Tuist/ProjectDescriptionHelpers`
- [ ] `SleepGuard`, `SleepGuardLite`, `Nocturne` each have their own bundle id, display name, icon, launch colour, entitlements
- [ ] Swift 6 language mode on all three
- [ ] `tuist generate` succeeds; each scheme builds and launches on the pinned simulator
- [ ] Generated project and workspace are git-ignored

### F1-T3 — Package skeletons

| Field | Value |
|-------|-------|
| Arch Ref | `modules.md`, `concurrency.md` |

**Acceptance Criteria:**
- [ ] `Core`, `Adapters`, `Presentation`, `Features`, `AppShell` packages with the products in `modules.md`
- [ ] Manifests express the import table (a forbidden import fails to compile)
- [ ] Swift 6 mode everywhere; `MainActor` default isolation only in features, `ScreenKit`, `AppShell`
- [ ] `SleepDomain` builds and tests on macOS with `swift test`
- [ ] Each package depends on `SleepGuardShared` only where the table allows

### F1-T4 — Design kit

| Field | Value |
|-------|-------|
| Arch Ref | `brands.md` |

**Acceptance Criteria:**
- [ ] `SleepGuardDesignKit` product in the shared repo: `Theme` (`Palette`, `Typography`, `Radii`), `@Environment(\.theme)`
- [ ] Default palette equals SleepGuard's tokens
- [ ] Primitive components with no domain types: stat card, score gauge, mini bar chart, level meter, buttons, sheet header, button style
- [ ] Re-exports `SleepStrings` (`@_exported import`); no dependency on `Models` or Factory
- [ ] Previews render in at least two themes

### F1-T5 — ScreenKit

| Field | Value |
|-------|-------|
| Arch Ref | `composition.md`, `navigation.md` |

**Acceptance Criteria:**
- [ ] `HostingScreen<Content>` injects the theme and applies `ScreenChrome`
- [ ] `Navigator` protocol with a `UINavigationController` implementation, including presentation-in-flight guards
- [ ] Child-containment helper for embedding a SwiftUI view
- [ ] Tests: chrome is applied; navigator calls reach UIKit

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
- [ ] `scripts/run-tests.sh` runs both lanes
- [ ] `scripts/check-layering.py`: forbidden imports, Factory outside `AppShell`, `.shared`, concurrency escape hatches, SwiftUI navigation APIs in features, `print(`
- [ ] `scripts/check-view-size.py`: 200-line limit with an allowlist that can only shrink
- [ ] Hardcoded-string check
- [ ] GitHub Actions on pull request: generate, build three schemes, tests, checks, SwiftFormat lint
- [ ] Each check is shown failing on a deliberate violation, then passing
