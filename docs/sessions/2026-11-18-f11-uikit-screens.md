---
date: 2026-11-18
feature: F11
branch: feature/f11/t1-uikit-screen-containers
title: Every screen a UIKit controller hosting the shared content
---

### Completed
- F11 planned with the owner as one task, then built: every screen is a UIKit `ScreenController` hosting the shared SwiftUI content (ADR 0007). The scope was widened mid-task from three screens to every SwiftUI view in this app.

### Technical Details
- ScreenKit:
  - `ScreenController` handles chrome, background, one state child, `host`, `hosted`, `render` (redraw in place), `renderTracking` (Observation) and the content scroll view.
  - `ContentListController` is a diffable, self-sizing list of content configurations.
  - `Typography.uiFont` gives UIKit text the theme's font.
  - `HostingScreen` is removed.
- History is a list `UICollectionView` with month headers; swipe and the alerts are UIKit. The list owns expansion, which needed `NightDayCard` to take `isExpanded` and `onToggle` (shared).
- Session Detail is a compositional layout over `NightDetailItems`, with a `UISegmentedControl` filter. Its loading and error states are UIKit views.
- Onboarding is a `UIPageViewController` with UIKit Skip and Back. The pages and dots are shared.
- Statistics screens share `NightsScreenController`. The dashboard reads the latest night's stages itself, replacing the SwiftUI `LatestNightStages`.
- Timers (countdown, bedside clock, melody recording) are owned tasks, cancelled on disappear. Alerts are methods so tests can check them.
- Diffable identifier enums in features are `nonisolated` (default MainActor isolation otherwise breaks `Sendable`).
- Shared repo, branch `feature/uikit-container-pieces`, made these public: `NightDayCard`, `NightMonthHeader`, `OnboardingPageView`, `OnboardingDots`, `NightDetailHeader` and `visibleRows`. It also gains a test for an expanded day. SleepGuard builds against it.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Presentation/Sources/ScreenKit/*` | `ScreenController`, `ContentListController`, `ThemeFonts`; `HostingScreen` removed; chrome applied by `ScreenChrome.apply(to:)` |
| `Packages/Features/Sources/*` | 21 screens as controllers; list/detail controllers and item builders; UIKit state views |
| `Packages/Features/Package.swift` | Features depend on ScreenKit; History test target |
| `Packages/Features/Tests/*` | History, detail items, onboarding, recording screens |
| `Packages/AppShell/Sources/*` | Composers and flows build the controllers |
| `Packages/AppShell/Tests/*`, `Apps/HostedTests/*` | Tests on the controllers |
| `scripts/check-layering.py`, `scripts/check-view-size.py` | New bans, controller size |
| `AGENTS.md`, `CLAUDE.md`, `README.md`, `docs/ARCHITECTURE.md`, `docs/COMPARISON.md`, `docs/architecture/*` | The new screen shape |
| `docs/adr/0007-uikit-screen-containers.md` | The decision |
| `docs/trackers/f11-…`, `docs/features/f11-…`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | F11 |
| `../SleepGuardShared/Sources/SleepGuardContentKit/{Nights,Onboarding}/*`, its gallery and test | Public pieces |

### Verified
- All four brands build.
- `run-tests.sh` passes on every lane, with the packages pointed at the local shared repo.
- The layering, view-size and string checks pass.
- The shared repo's tests pass, and SleepGuard builds against it.
- In the simulator I checked the dashboard, the Sessions list and the night detail.
- After the owner tagged 0.28.0: pinned with `bump-shared.sh`; all lanes pass and all four brands build on the release (`TUIST_SHARED_RELEASE=1`).

### Not verified
- Onboarding on a fresh install, swipe to delete and the other brands were not checked by eye.

### Follow-ups
- There are pre-existing swiftformat violations in untouched files.
