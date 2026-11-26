# F13 — Architecture review fixes

> Updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P0 (T1–T5) / P1 |
| **Milestone** | M5 |
| **Blocked By** | — |
| **Started** | 2026-11-26 |
| **Completed** | — |
| **Feature Doc** | — |
| **Branch** | `feature/f13-architecture-review` (task branches `feature/f13/t#-slug`, merged by the owner through PRs) |

## Summary

Fixes this app's verdicts from the principal-level architecture review of the three repos, each checked against the code first: stale stored scores after a formula change, a detail load that writes, store observation, a silent in-memory store, detection fed per buffer instead of at SleepGuard's 20 Hz, interruptions not recorded, I/O on the sample path, the global brand key and whole-container flows, navigator races, an oversized recording flow, a non-atomic day delete and static chrome, deep links promised but missing, fakes that can drift from adapters, regex-only bans, and CI cost. SleepGuard and the shared repo were fixed first (SleepGuard F27; shared 0.29.1 and 0.30.0).

### Decisions (owner, 2026-11-26)
- Scope: the review's verdicts plus deep links, the recording-flow split, day delete and dynamic chrome, structural lint with CI and a theme check.
- The 20 Hz decimation lives in `RecordingSession` (the domain owns the rule).
- Git: a feature branch with a PR per task; the owner commits and merges.

## Tasks

| ID | Task | Type | Status | Depends On | Where |
|----|------|------|--------|------------|-------|
| F13-T1 | Adopt shared 0.30.0 and `SaveRules` | Dependency | Done | — | all packages, AppShell |
| F13-T2 | Stored scores carry their version; refresh at launch (Q9) | Bug / Data | Done | T1 | SleepDomain, SleepPersistence, AppShell |
| F13-T3 | Detail load is read-only; narrow stage writes (Q34, Q37) | Refactor | Done | T2 | SleepDomain, SleepPersistence, SessionDetailFeature |
| F13-T4 | Observation follows the store (Q37) | Bug | Done | T3 | SleepPersistence |
| F13-T5 | "We couldn't open your data" + shared 0.31.0 (Q55) | Data safety | In Progress (waits for the 0.31.0 tag) | T4 | shared, AppShell |
| F13-T6 | Same samples as SleepGuard; interruptions; FFT; thermal (Q14, Q17) | Detection | Done | T1 | SleepDomain, SleepAudio |
| F13-T7 | Writes leave the sample path (Q13, Q39) | Performance | Done | T6 | SleepDomain |
| F13-T8 | Typed composition (Q47, Q48) | Architecture | Backlog | T5 | AppShell, Apps |
| F13-T9 | Navigator races (Q45) | Bug | Done | — | ScreenKit, AppShell |
| F13-T10 | Split `RecordingFlow` (Q44) | Refactor | Backlog | T8 | AppShell |
| F13-T11 | Atomic day delete; dynamic chrome (Q38, Q43) | Bug / UI | Backlog | T5 | SleepDomain, SleepPersistence, ScreenKit, features |
| F13-T12 | Deep links (Q28) | Feature | Backlog | T8 | Apps, AppShell |
| F13-T13 | Port contract tests (Q59) | Tests | Backlog | — | SleepDomain, Adapters |
| F13-T14 | Structural lint, theme check, CI (Q63, Q51, Q62) | Tooling | Backlog | — | ScreenKit, scripts, CI |
| F13-T15 | Docs and close-out | Docs | Backlog | all | docs |

## Task Details

### F13-T1 — Adopt shared 0.30.0 and `SaveRules`

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] Every manifest and `Project.swift` pin 0.30.0; resolved files follow
- [x] The 0.30.0 compatibility changes: `.interruptionGap` handled in `RecordingSession`; the gap banner shows melody gaps only
- [x] `SaveRules` replaces the deprecated `Night.minimumSaveDuration` everywhere; the composition registers it (Debug 120 s, Release `.standard`)
- [x] All four brands build; all lanes pass on the release (`TUIST_SHARED_RELEASE=1`); checks pass

**Notes:**
- `saveRules` is a container registration (Debug 120 s, Release `.standard`), passed into `CommitSession`, `ShouldAskForProfile`, `SessionSummaryViewModel` and `LiveRecordingModel`; both "too short" alerts read the minutes from it. Nothing references `Night.minimumSaveDuration` any more, so 0.31.0 can remove it.
- Verified on the release (`TUIST_SHARED_RELEASE=1`): all four brands build; Core 65, Adapters 18, Presentation 18, Features 6, AppShell 70, hosted 9 × 4 pass; layering, view size and strings checks pass.
- SwiftFormat 0.55.5 flags three files this task didn't touch (`FileMelodyStoreTests`, `AVMelodyRecorder`, `SnoreInterrupter`), already on `main`; left alone.
- Branch `feature/f13/t1-shared-0-30-save-rules`

### F13-T2 — Stored scores carry their version; refresh at launch

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] Every saved summary stores `SleepScore.cacheVersion(for:)`; nights stored before read as stale (`scoreVersion = ""`, additive)
- [x] `RefreshStaleSummaries` recomputes stale summaries at launch, in batches, writing summary columns only
- [x] It runs before the morning briefing reads scores
- [x] Tests: use case (fake), adapter (stale query, events untouched), and a pre-change store opens

**Notes:**
- Port: `save(_:summary:scoreVersion:)`, `staleNightIDs(currentVersion:)` (reads id, start, version only), `updateSummaries(_:scoreVersion:)` (one save and one list update per batch of 20; a night deleted meanwhile is skipped).
- A night that fails to load stays stale and is retried at the next launch. A refresh failure is logged and doesn't block the storage limits.
- Checked on the simulator: a store from 2026-11-18 (14 nights, no version column) opened after the change with every night intact, and all 14 came out stamped `2-…` (scores 70–100).
- Branch `feature/f13/t2-score-version`

### F13-T3 — Detail load is read-only; narrow stage writes

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] `LoadSessionDetail` only reads (tested: no write)
- [x] `EnrichNightWithStages` adds stages through the new port method `updateStages(of:stages:summary:scoreVersion:)`: stage blob and summary columns only, events untouched (tested on SwiftData: same event records)
- [x] A failed stage save no longer fails the night's load: the screen shows the stages, the store keeps the night without them, the next open retries (tested at use case and view model)

**Notes:**
- The view model loads, shows the night, then enriches; only the load can put the screen in its error state.
- The failure is not logged: SleepDomain and the view models have no logger by design (layering). Same handling as the stage source failing, which was already silent.
- `FakeSessionRepository.failStageUpdates(with:)` added for the view-model case.
- Branch `feature/f13/t3-read-only-detail`

### F13-T4 — Observation follows the store

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] A committed write never throws because the re-read for observers failed (logged instead)
- [x] Every write publishes, `removeClips` included (tested for all seven write kinds)
- [x] The single-writer assumption is written down where it holds

**Notes:**
- **Scope changed from the plan, on evidence:** the plan said to observe other contexts' saves. There are none: the container makes one store (singleton) and nothing else opens the database (no widget, extension or sync). Observing `ModelContext.didSave` would be code for a writer that doesn't exist, and awkward under Swift 6 (contexts aren't Sendable). The store's doc now says a second writer needs persistent-history observation first.
- Branch `feature/f13/t4-store-observation`

### F13-T5 — "We couldn't open your data" + shared 0.31.0

| Field | Value |
|-------|-------|
| Status | In Progress (waits for the owner's 0.31.0 tag) |
| Started | 2026-11-26 |

**Done so far:** shared branch `f13-store-unavailable-content` (pushed): `StoreUnavailableContent`, export-failed and day-delete-failed strings, `Night.minimumSaveDuration` removed; shared tests pass. Here, on `feature/f13/t5-store-unavailable` (pushed, not merged): `StoreOpening` (repository + whether the file opened), `AppCoordinator` shows only `StoreUnavailableViewController` when it didn't (no recovery, recording or seeding). Tested against the local shared checkout: corrupt-file test (file kept byte for byte), coordinator test; simulator: a corrupt store shows the screen and keeps the file; the real store was restored (14 nights). **Left:** bump to 0.31.0, all lanes on the release, merge.

### F13-T6 — Same samples as SleepGuard; interruptions; FFT; thermal

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] `RecordingSession` decimates readings to 20 Hz with SleepCore's `SampleDecimator` (43 Hz and 47 Hz input give the same events, about 600 samples per 30 s)
- [x] The capture stream carries `CaptureEvent` (`sample`, `interrupted`, `resumed`); the session sends `captureDidPause` / `captureDidResume` and restarts the grid (a call mid-event ends the event and leaves a 60 s `.interruption` gap; mutation-checked)
- [x] The adapter reports interruptions, resumes when one ends with or without `.shouldResume`, and after a media-services reset
- [x] The FFT runs only with the raw recording; thermal state logged at start and on change
- [x] README's parity sentence is accurate

**Notes:**
- No `didBecomeActive` retry: SleepAudio doesn't import UIKit (layering). A failed resume is logged and retried at the next route, configuration or media-services event. The device night should show whether that is enough.
- Raw log and snapshots now run at 20 Hz; `rawLogBatch` 40 → 20 (one second).
- `docs/ARCHITECTURE.md`'s capture section is left for T15: the file has the owner's uncommitted edits.
- Simulator raw-log spacing check skipped: the decimator tests prove the spacing; the device night (owner) covers the microphone.
- Branch `feature/f13/t6-capture-parity`

### F13-T7 — Writes leave the sample path

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] `receive` and `perform` never await disk I/O: checkpoints go to a latest-wins writer task, raw-log batches to a serial one (both on the session actor, so ordering needs no locks)
- [x] A stuck disk for twenty minutes of night: samples keep flowing (about 24,000), and once it frees only the stuck save and the newest night are written (`[0, 1080]`), not ten
- [x] `stop` drains both writers before its final save; nothing lands after it (so commit's `clear` and discard always win)
- [x] Raw log still gets every sample, in order

**Notes:**
- No sequence gate needed, unlike SleepGuard's F27-T6: here the writers belong to the session and `stop` awaits them, and the checkpoint is only cleared after `stop` returns (`CommitSession`, discard).
- Branch `feature/f13/t7-off-path-writes`

### F13-T9 — Navigator races

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] The navigator runs operations one at a time, in order; each waits until nothing is moving and picks its presenter only then
- [x] `dismiss(_:)` dismisses the controller a flow presented (through its presenter, so an alert over it goes too); the untargeted `dismiss()` is gone. Flows use `present(style:) { close in … }`, whose `close` is bound to that controller
- [x] `presentAlert` waits for the screen's own transition
- [x] Hosted tests: an alert over a sheet goes with the sheet (mutation-checked: asking the sheet instead of its presenter leaves the sheet up); present, dismiss, present in one animated turn ends with the second sheet. The suite has a time limit and its waits end on cancellation, so a regression fails in a minute instead of hanging
- [x] `NavigatorSpy` records the dismissed controller; flow tests assert the right one closes

**Notes:**
- Scope grew from the plan: a targeted dismiss alone would drop a dismiss asked for before its present had happened. The serial queue covers that; `presentAlert` doesn't go through it (screens own their alerts, ADR 0008).
- Branch `feature/f13/t9-navigator-races`
