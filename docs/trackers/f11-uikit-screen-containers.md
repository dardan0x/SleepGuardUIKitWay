# F11 — UIKit screen containers

> Updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P2 |
| **Milestone** | M4 |
| **Blocked By** | — |
| **Started** | 2026-11-18 |
| **Completed** | 2026-11-18 |
| **Feature Doc** | [f11-uikit-screen-containers.md](../features/f11-uikit-screen-containers.md) |

## Summary

Every screen in this app is now a UIKit view controller (ADR 0007). UIKit owns each screen's structure, state, loading and alerts; shared SwiftUI from `SleepGuardContentKit` and `SleepGuardDesignKit` draws the cells, pages and content inside it. History is a diffable collection-view list, Onboarding a `UIPageViewController`, Session Detail a compositional collection view with a native segmented filter; the remaining screens host their shared content in `ScreenController` or `ContentListController`. Planned with the owner on 2026-11-18: UIKit containers, not thin wrappers or pure UIKit views. The scope was first History, Onboarding and Session Detail, and was widened by the owner mid-task to "everything that imports SwiftUI and is not in SleepGuardShared". SleepGuard renders the same; the shared repo gains public pieces only.

**The line:** UIKit decides where things go, how they move and what state the screen is in. Shared SwiftUI draws. Navigation is still the coordinators' job.

## Tasks

One task, at the owner's request.

| ID | Task | Type | Status | Depends On | Where | Acceptance (short) |
|----|------|------|--------|------------|-------|--------------------|
| F11-T1 | Every screen a UIKit controller hosting the shared content | Architecture / UI / Shared | Done | F10 | ScreenKit, Features, AppShell, shared repo | All 21 screens are `ScreenController`s; every brand builds; tests and checks pass |

## Task Details

### F11-T1 — UIKit screen containers

| Field | Value |
|-------|-------|
| Arch Ref | `docs/architecture/composition.md`, ADR 0007 (amends 0001 and 0005) |
| Branch | `feature/f11/t1-uikit-screen-containers` (shared repo: `feature/uikit-container-pieces`) |
| Status | Done |
| Started | 2026-11-18 |
| Completed | 2026-11-18 |

**Acceptance Criteria:**

*Rules, ADR, ScreenKit*
- [x] ADR 0007: every screen a UIKit controller; navigation unchanged; alerts only; ADR 0005 narrowed (container layout of History, Detail, Onboarding is UIKit here, drift risk stated)
- [x] `AGENTS.md` and `CLAUDE.md` in sync: module table, "Screens (UIKit, hosting shared SwiftUI content)", composition, theme, testing, concurrency notes
- [x] `check-layering.py`: UIKit and ScreenKit allowed in features; `UINavigationController`, `navigationController`, `pushViewController`, `Navigator` and non-alert `present(` banned (checked against sample lines)
- [x] `check-view-size.py`: `*Controller.swift` ≤ 200 lines
- [x] ScreenKit: `ScreenController` (chrome, background, state child, `host`, `hosted`, `render`, `renderTracking`, content scroll view for large titles), `ContentListController`, `Typography.uiFont`; `HostingScreen` removed; 17 tests

*Shared (0.28.0)*
- [x] Public: `NightDayCard` (expansion owned by the list), `NightMonthHeader`, `OnboardingPageView`, `OnboardingDots`, `NightDetailHeader`, `NightDetailContent.visibleRows`
- [x] SleepGuard renders the same (shared content rebuilt from the pieces; SleepGuard builds); new test: an expanded day shows its nights; shared tests pass
- [x] Released (0.28.0, tagged by the owner) and pinned here with `bump-shared.sh 0.28.0`

*Screens*
- [x] History: diffable list, month headers, hosted day cards, list-owned expansion, swipe to delete, `UIAlertController` confirm and failure, live updates; `NightsListItems` tested
- [x] Session Detail: compositional layout, hosted sections, `UISegmentedControl` filter, UIKit events title and "Show all", UIKit loading and error views, retry; `NightDetailItems` tested
- [x] Onboarding: `UIPageViewController`, hosted pages and dots, UIKit Skip and Back, permissions and the 0.8 s pause as before; tests
- [x] Statistics, Trends, Calendar, Last 7 Nights (one `NightsScreenController` base), the dashboard with the stages read and the profile prompt
- [x] Player and events sheet (`ContentListController`), stages sheet, Settings, profile editor, prestart, countdown, bedside clock, summary, record melody, interrupter, melody picker, Learn, Briefing
- [x] Composers, flows and every test moved to the controllers

*Verification*
- [x] All four brand schemes build (SleepGuard, SleepGuardLite, Nocturne, Dawn)
- [x] `run-tests.sh` all lanes pass on the pinned 0.28.0; every brand builds with `TUIST_SHARED_RELEASE=1` (what CI builds)
- [x] Layering, view-size and hardcoded-string checks pass; touched files lint clean
- [x] Simulator (SleepGuard brand): dashboard with large title, Sessions list, night detail with the segmented filter
- [ ] Simulator: onboarding on a fresh install, swipe to delete, expanding a day, the other brands: not seen by eye (onboarding and flows are covered by tests)

**Prompt Used:**
"Is there a way, without breaking the architecture, to use UIKit programmatically around the SleepGuardContentKit views (History, Onboarding, SessionDetail)… make a plan and include it in the trackers and roadmap", then "keep working in this branch until you're all done", then "use UIKit also for everything that can be converted from SwiftUI… everything importing SwiftUI that is not in SleepGuardShared".

**Notes:**
- Features still import SwiftUI, only to host shared views and build `Binding`s into them; no SwiftUI layout is written in a feature.
- Existing format violations in untouched files (Core, Adapters) were left alone.

## Update Rules (for the AI)

After completing the task:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in the task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. Set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)
