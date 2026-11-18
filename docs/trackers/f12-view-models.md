# F12 — View models and factories

> Updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P2 |
| **Milestone** | M4 |
| **Blocked By** | — |
| **Started** | 2026-11-18 |
| **Completed** | 2026-11-18 |
| **Feature Doc** | [f12-view-models.md](../features/f12-view-models.md) |

## Summary

Every screen now has a view model (ADR 0008; checked): `@MainActor @Observable`, no UI imports (checked), tested with the fakes. It holds the state, calls the use cases and routes, and says which alert is due. The UIKit controller only draws it, forwards taps, runs its async work in tasks it owns, and presents its alerts. The flows' composers became factories that build the dependencies, then the view model, then the controller. Decided with the owner on 2026-11-18: the existing per-flow composers as the factories (no per-screen factory types). First built with view models only where there was state or logic; the owner then asked for one on every screen, which the layering check now enforces. It reverses ADR 0001's "no view models", whose reason ended when the screens became UIKit (F11).

## Tasks

One task, at the owner's request. Started on the F11 branch, finished on `feature/f12/t1-view-models`.

| ID | Task | Type | Status | Depends On | Where | Acceptance (short) |
|----|------|------|--------|------------|-------|--------------------|
| F12-T1 | A view model for every screen; composers become factories | Architecture / Refactor | Done | F11 | Features, AppShell, ScreenKit, scripts, docs | 19 view models for 21 screens (checked); factories build them; every brand builds; tests and checks pass |

## Task Details

### F12-T1 — View models and factories

| Field | Value |
|-------|-------|
| Arch Ref | ADR 0008, `docs/architecture/composition.md` |
| Branch | `feature/f12/t1-view-models` (started on `feature/f11/t1-uikit-screen-containers`) |
| Status | Done |
| Started | 2026-11-18 |
| Completed | 2026-11-18 |

**Acceptance Criteria:**
- [x] ADR 0008; `AGENTS.md` and `CLAUDE.md` in sync: module table row for view models, the screen and factory rules, testing
- [x] `check-layering.py`: a feature's `*ViewModel.swift` imports only Foundation, Observation, `SleepDomain`, `SleepCore`
- [x] View models: History, Session Detail, Onboarding, Statistics, `NightsViewModel` (Trends, Calendar, Last 7 Nights), Settings, Profile editor, Prestart, Countdown, Bedside clock (over `LiveRecordingModel`), Summary, Record melody, Snore Interrupter, Melody picker. `ClipPlaybackModel` renamed `PlayerViewModel`
- [x] The screens that only show values have one too: `LearnViewModel`, `BriefingViewModel`, `EventsSheetViewModel`, `SleepStagesInfoViewModel`; `BriefingFactory` replaces the inline build in `AppCoordinator`
- [x] `check-layering.py`: a feature class subclassing `ScreenController` without `let viewModel` fails (checked against sample lines)
- [x] No `@ObservationIgnored` (`let`s aren't tracked; renders read only what they draw)
- [x] Controllers draw (`renderTracking`), forward, own the tasks, present alerts (`ScreenController.presentAlert`) and never call a route
- [x] Composers renamed factories (`HistoryScreenFactory`, `SessionDetailFactory`, `StatisticsFactory`, `SettingsFactory`, `RecordingFactory`); the onboarding and Learn screens moved out of their flows into `OnboardingFactory` and `LearnFactory`
- [x] View-model tests: History, Session Detail, Onboarding, Prestart, Countdown, Summary, Record melody, Melody picker, Settings (new `SettingsFeatureTests` target); flow and in-app tests go through `viewModel`
- [x] `FakeMelodyRecorder` fixed to keep the take at the limit, as `AVMelodyRecorder` does (found by the new test)
- [x] Docs: composition, feature template, rules, dependencies, README, ARCHITECTURE, COMPARISON
- [x] Every brand builds; `run-tests.sh` all lanes pass; layering, view-size, string checks pass; touched files formatted
- [ ] Simulator walk-through: not repeated for F12 (the screens draw the same; flows and in-app tests cover the wiring)

**Prompt Used:**
"I think view controllers would benefit from view models to further separate concerns… right now every view controller… is holding too much, even presentation logic like router… introduce factories to create these view models and view controllers and pass dependencies in a clean way respecting our hexagonal architecture."

**Notes:**
- Types the shared content owns (`TrendsRange`, `MelodyRecordingState`, `OnboardingPermission`) can't be imported by a view model. The view model has its own value and the controller maps it; Trends' range is a pure view selection and stays in its controller.
- A view model's `routes` and `dependencies` are internal (read-only), so flow tests can reach them.
- `docs/architecture/` is git-ignored in this repo, so its updates (F11 and F12) are local only. Worth a decision.

## Update Rules (for the AI)

After completing the task:
1. Check off acceptance criteria boxes
2. Fill Started/Completed dates in the task table and detail section
3. Set task Status to **Done**
4. Fill "Prompt Used" with the prompt summary
5. Add any notes about decisions or deviations
6. Set feature Status to **Done**, fill Completed date
7. Also update the index file (docs/FeatureTracker.md)
