---
date: 2026-11-18
feature: F12
branch: feature/f12/t1-view-models
title: A view model for every screen, built by the flows' factories
---

### Completed
- F12-T1, planned with the owner:
  - The composers become the factories.
  - One task. Started on the F11 branch, moved to `feature/f12/t1-view-models`.
- First built with view models only where there was state or logic. The owner then asked for one on every screen, so Learn, Briefing, the events sheet and the stages sheet got one too, and the layering check now fails a screen without one.
- `@ObservationIgnored` removed everywhere: `let`s aren't tracked, and renders read only what they draw.
- ADR 0008 reverses ADR 0001's "no view models".

### Technical Details
- **View models:** 19 for 21 screens, `@MainActor @Observable`. Each holds a `State` enum, the draft or selection, an `Alert?` value, `async` intents and its `Routes`. They import only Foundation, Observation, `SleepDomain` and `SleepCore`, which `check-layering.py` enforces by file name.
- **Controllers** draw the view model through `renderTracking`, forward taps to it, own its tasks, and map its `Alert` to a `UIAlertController`.
  - `ScreenController.presentAlert(_:make:)` presents an alert once while none is showing.
  - Values read lazily by a binding (the calendar's month, the profile) are read during rendering, so a change still redraws.
- **Content-kit types** (`TrendsRange`, `MelodyRecordingState`, `OnboardingPermission`) stay out of view models. The view model has its own enum and the controller maps it.
- **Factories:**
  - `HistoryScreenFactory`, `SessionDetailFactory`, `StatisticsFactory`, `SettingsFactory` and `RecordingFactory` were the composers.
  - `OnboardingFactory`, `LearnFactory` and `BriefingFactory` are new; those screens used to be built inline in their flow or in `AppCoordinator`.
- **Renames:** `ClipPlaybackModel` → `PlayerViewModel`. `LiveRecordingModel` stays, under `BedsideClockViewModel`.
- **A fake fixed:** the new melody test showed that `FakeMelodyRecorder` lost the take at the time limit, where `AVMelodyRecorder` keeps it.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Features/Sources/*/*ViewModel.swift` | 18 view models (new), `PlayerViewModel` (renamed) |
| `Packages/Features/Sources/*/*ViewController.swift`, `NightDetailController.swift`, `NightsScreenController.swift` | Draw the view models |
| `Packages/Features/Tests/*`, `Package.swift` | View-model tests; `SettingsFeatureTests` |
| `Packages/AppShell/Sources/AppShell/*` | Composers → factories; Onboarding and Learn factories |
| `Packages/AppShell/Tests/*`, `Apps/HostedTests/*` | Routes reached through `viewModel` |
| `Packages/Presentation/Sources/ScreenKit/ScreenController.swift` | `presentAlert(_:make:)` |
| `Packages/Core/Sources/SleepDomainTestSupport/FakeMelodyPorts.swift` | Recorder keeps the take at the limit |
| `scripts/check-layering.py` | View-model import rule; every screen declares a view model |
| `AGENTS.md`, `CLAUDE.md`, `README.md`, `docs/ARCHITECTURE.md`, `docs/COMPARISON.md`, `docs/architecture/*` | View models and factories |
| `docs/adr/0008-view-models.md`, `docs/trackers/f12-view-models.md`, `docs/features/f12-view-models.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | F12 |

### Verified
- Every brand builds.
- `run-tests.sh` passes on all lanes.
- The layering, view-size and string checks pass.
- The touched files are formatted.

### Not verified
- I didn't walk through the app in the simulator again. The screens draw what they drew before, and the flow and in-app tests cover the wiring.

### Follow-ups
- `docs/architecture/` is git-ignored, so its notes (F11, F12) live only on this machine.
