# F13 — Architecture review fixes

**Status:** Done (2026-11-26) · **Branch:** `feature/f13-architecture-review` (a task branch per task) · **Tracker:** [f13](../trackers/f13-architecture-review.md)

A principal-level review of the three repos (`ARCHITECTURE_INTERROGATION.md`) asked where the honest answer was "we'd change this". SleepGuard and the shared repo were fixed first (SleepGuard F27; shared 0.29.1 and 0.30.0). F13 fixes this app's verdicts plus the extras the owner chose (deep links, the recording flow split, day delete and chrome, structural lint with CI and a theme check). Every concern was checked against the code before planning. Most held, some were worse than stated (formula v2 made every stored score stale; a failed save stopped a night from opening; the fake repository broke the port's event order; the bootstrap test resolved half the container), and one was wrong (export already had a re-entry guard). Shared 0.31.0 was written here and tagged by the owner.

## What changed, by concern

| Concern (review Q) | Before | After |
|---|---|---|
| Shared release (Q3) | Pinned 0.29.0; the save minimum branched on the shared package's build | 0.31.0; `SaveRules` from the composition (Debug 2 min) (T1, T5) |
| Stored scores (Q9) | No version; formula v2 made them all stale | `scoreVersion` stored; stale ones recomputed at launch, in batches, summary columns only (T2) |
| Detail writes (Q34, Q37) | Opening a night re-saved it whole; a failed save failed the open | A read-only load, then a narrow `updateStages` (T3) |
| Observation (Q37) | A failed re-read made a committed write throw; `removeClips` told nobody | Every write publishes, never throws; one-writer rule written down (T4) |
| Store won't open (Q55) | Silent in-memory store, nights lost | "We couldn't open your sleep data" and nothing else; the file kept (T5) |
| Detection input (Q14, Q17) | One sample per buffer (43–47 Hz); a call counted as quiet; no resume without `.shouldResume`; FFT always on | 20 Hz via `SampleDecimator`; calls are interruption gaps; resume always; FFT only with the raw log; thermal logged (T6) |
| Disk on the sample path (Q13, Q39) | Checkpoints and raw log awaited per sample and per output | Latest-wins and serial writer tasks; `stop` drains them (T7) |
| Composition (Q47, Q48) | `Container.shared`; brand key `preconditionFailure`; flows took the whole container; `try!` | `AppComposition` per brand; flows take what they use; per-container scope; every registration resolved by a test (T8) |
| Navigator (Q45) | Presenter picked before waiting; dismiss took the top (an alert instead of its sheet) | Serial operations, presenter picked when idle; targeted dismiss (T9) |
| Recording flow (Q44) | 248 lines, 9 jobs; a leaked task | `InterrupterSettingsNavigation` and `NightLifecycle`; 154 lines (T10) |
| Day delete, chrome (Q38, Q43) | A loop that could delete half a day; static bar items; report failures only logged | `delete(ids:)` all or none; `BarItemActivity`; a failure alert (T11) |
| Deep links (Q28) | Declared schemes, no handling | `AppRoute` via the app coordinator, held while busy (T12) |
| Fakes (Q59) | Nothing checked fakes against adapters | `PortContracts` run on both; one drift fixed (T13) |
| Shared behaviour (owner, after close-out) | Own HealthKit and raw-log code, drifting from SleepGuard's | `HealthKitSleep` and `RawLogFile` from shared 0.32.0, wrapped by the adapters (T16); settings are the shared `SleepPreferences` stored by `PreferencesDefaults` (0.33.0, T17) |
| Lint, theme, CI (Q63, Q51, Q62) | A regex for `present(`; hand-themed hosting; every brand fully on every PR | Unavailable `present` (compile error); hosting only through ScreenKit; one reference brand per PR, all nightly; SwiftPM cache (T14) |

## Files

| Area | Files | Purpose |
|---|---|---|
| Domain | `Ports/{SessionRepository,AudioCapture}.swift`, `UseCases/{RefreshStaleSummaries,LoadSessionDetail,DeleteSession,CommitSession,ShouldAskForProfile}.swift`, `Recording/RecordingSession.swift` | Versioned summaries, narrow writes, `delete(ids:)`, `CaptureEvent`, decimation, off-path writes |
| Test support | `PortContracts.swift` (new), `FakeSessionRepository.swift`, `FakeAudioCapture.swift` | Contracts; fakes that meet them |
| Adapters | `SwiftDataSessionStore.swift`, `Records.swift`, `RecordMapping.swift`, `EngineAudioCapture.swift`, `CaptureProcessor.swift` | Score version, stages, all-or-none delete, publishing; interruptions, FFT gate, thermal |
| ScreenKit | `Navigator.swift`, `ScreenController.swift`, `ScreenChrome.swift`, `ThemedHosting.swift` (new) | Serial navigator, targeted dismiss, unavailable `present`, `BarItemActivity`, `Theme.hosting` |
| Features | `OnboardingFeature/StoreUnavailable{ViewController,ViewModel}.swift` (new), History, SessionDetail, Recording view models and controllers | Store-unavailable screen; day delete; enrich after load; `SaveRules` |
| AppShell | `Composition/AppComposition.swift`, `Routing/AppRoute.swift`, `Recording/{InterrupterSettingsNavigation,NightLifecycle}.swift` (new); `AppShell.swift`, `Container+AppShell.swift`, `AppCoordinator.swift`, `MainTabCoordinator.swift`, every flow, `NightDetailNavigation.swift`, factories | Composition root, links, recording split, store opening |
| Apps | `Apps/Shared/Sources/SceneDelegate.swift`, `Apps/HostedTests/*` | Links in; tests reach the running composition; bootstrap covers every registration; leak and navigator race checks |
| Scripts / CI | `check-layering.py`, `run-tests.sh`, `.github/workflows/ci.yml` | No `Container.shared`; hosting rule; reference brand |
| Docs | ADRs 0009–0012; `ARCHITECTURE.md`, `README.md`, `AGENTS.md`/`CLAUDE.md`, `CODING_WORKFLOW.md` | Decisions and current facts |
| Shared 0.31.0 | `StoreUnavailableContent` (+ gallery, tests), strings, `Night.swift` | The screen's content; export and day-delete strings; the deprecated minimum removed |

Tests: 291 package tests (from about 210) and 13 in-app tests per brand (from 9).

## Routes

| Kind | Added |
|---|---|
| Link | `<scheme>://start`, `<scheme>://session/<id>`, `<scheme>://last7nights` (`AppRoute`) |
| Launch screen | Store unavailable (instead of the onboarding or the tabs) |

## State

| State | Where | Scope |
|---|---|---|
| Score version | `SessionRecord.scoreVersion` | Per night, stored |
| Store opened | `StoreOpening` | Per composition (launch) |
| Pending link | `AppCoordinator.pendingRoute` | Memory, one launch |
| Decimator window | `RecordingSession` | A night |
| Pending checkpoint / raw batches | `RecordingSession` writers | A night |
| Report in progress | `BarItemActivity` | A night's detail |

## Edge cases

- A call mid-snore ends the event at its last sample; the call is a gap left out of the score.
- A disk stuck for twenty minutes: samples keep flowing; when it frees, only the newest night is written.
- A store file that can't be opened stays byte for byte; the app shows only its screen.
- A link to a night deleted since: the app stays where it is. "Start" during a night: dropped. Any link during the briefing or a night: opened after.
- A day delete that fails: every night and clip of the day stays.
- An alert over a sheet goes with the sheet when the flow closes it.

## Limits

- Device night (owner): the decimator cadence, interruption gaps, resume without `.shouldResume` (no foreground retry: SleepAudio has no UIKit), thermal logs.
- Factory remains under the composition; the bootstrap test is the guard for missing registrations (ADR 0009).
- `COMPARISON.md`'s line counts date from F12.
- Seen once: `PlayerInAppTests` timed out in one full run (real audio on the simulator); passed on reruns.
- Not done, by decision: a remote kill switch (Q50, no config backend), a shared task-scope type (Q54), merging thin view models (Q41, ADR 0008).

## Tasks Completed

F13-T1 … F13-T17.

## Uniform the apps (T18–T21)

The owner's later request: the adapters' behaviour moves to the shared repo ([ADR 0013](../adr/0013-uniform-apps.md)).

| Release | Task | What moved |
|---|---|---|
| 0.34.0 | T18 | Logging, live classification, sample nights, file layout and files, storage sweep, start notification |
| 0.35.0 | T19 | `SleepAudio`'s implementations → `SleepAudioKit` (ports unchanged, `KitConformances.swift`) |
| 0.36.0 | T20 | `SleepPersistence`'s records, mapping and schema → `SleepStore` (the actor and its contract stay) |
| — | T21 | ADR 0013, ARCHITECTURE, AGENTS/CLAUDE |

Files the table above lists in `SleepAudio/Capture/` and `SleepPersistence/Records/` are now in the shared repo.

