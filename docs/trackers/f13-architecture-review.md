# F13 — Architecture review fixes

> Updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P0 (T1–T5) / P1 |
| **Milestone** | M5 |
| **Blocked By** | — |
| **Started** | 2026-11-26 |
| **Completed** | 2026-11-26 |
| **Feature Doc** | [f13-architecture-review.md](../features/f13-architecture-review.md) |
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
| F13-T5 | "We couldn't open your data" + shared 0.31.0 (Q55) | Data safety | Done | T4 | shared, AppShell |
| F13-T6 | Same samples as SleepGuard; interruptions; FFT; thermal (Q14, Q17) | Detection | Done | T1 | SleepDomain, SleepAudio |
| F13-T7 | Writes leave the sample path (Q13, Q39) | Performance | Done | T6 | SleepDomain |
| F13-T8 | Typed composition (Q47, Q48) | Architecture | Done | T5 | AppShell, Apps |
| F13-T9 | Navigator races (Q45) | Bug | Done | — | ScreenKit, AppShell |
| F13-T10 | Split `RecordingFlow` (Q44) | Refactor | Done | T8 | AppShell |
| F13-T11 | Atomic day delete; dynamic chrome (Q38, Q43) | Bug / UI | Done | T5 | SleepDomain, SleepPersistence, ScreenKit, features |
| F13-T12 | Deep links (Q28) | Feature | Done | T8 | Apps, AppShell |
| F13-T13 | Port contract tests (Q59) | Tests | Done | — | SleepDomain, Adapters |
| F13-T14 | Structural lint, theme check, CI (Q63, Q51, Q62) | Tooling | Done | — | ScreenKit, scripts, CI |
| F13-T15 | Docs and close-out | Docs | Done | all | docs |

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
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] Shared 0.31.0 (owner merged and tagged): `StoreUnavailableContent` (update button optional), export-failed and day-delete-failed strings, `Night.minimumSaveDuration` removed
- [x] Pinned 0.31.0 everywhere
- [x] `StoreOpening` (the repository and whether its file opened); when it didn't, `AppCoordinator` shows only `StoreUnavailableViewController` (in OnboardingFeature, the launch screens): no tabs, recovery, recording or sample nights reach the in-memory store. The update button opens the brand's App Store page, or is left out when the brand has none
- [x] Tests: a corrupt file is kept byte for byte and the store is marked unavailable; a good file opens; the coordinator shows only that screen. Simulator: a corrupt store shows the screen and keeps the file; the real store (14 nights) was restored afterwards

**Notes:**
- The store registrations are `.cached` (once per container), not `.singleton`: Factory's singleton is one per process, so one test's container could get another's store (it made the corrupt-file test fail when the good-file test ran first).
- SleepGuard could host the same shared content later; its own view stays for now.
- Branch `feature/f13/t5-store-unavailable`

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

### F13-T13 — Port contract tests

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] `SleepDomainTestSupport.PortContracts`: one contract per port with state (`SessionRepository`, `RecordingCheckpointStore`, `ProfileStore`, `LifestyleLogStore`, `PreferencesStore`, `MelodyStore`), returning violations as lines (the support module needs no test framework)
- [x] Run against every fake (SleepDomainTests) and every adapter (SleepPersistenceTests, SleepAudioTests; both now declare `SleepDomainTestSupport`)
- [x] The drift it found is fixed: `FakeSessionRepository` returned events in save order; now in time order, as the port and the SwiftData store do. Every adapter already met its contract
- [x] Effect-only fakes (players, capture, Health, recorder) stay spies, as the contract file says

**Notes:**
- Branch `feature/f13/t13-port-contracts`

### F13-T14 — Structural lint, theme check, CI

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] A screen that presents anything but an alert doesn't compile: `ScreenController.present` is `@available(*, unavailable)` (checked that Swift accepts an unavailable override and rejects a subclass's call); `presentAlert` presents through `super`. The regex in rule 5 stays as a backstop for feature controllers that aren't screens
- [x] Themed hosting: only ScreenKit creates `UIHostingController` / `UIHostingConfiguration` (layering rule 9; it flags the old hand-themed sites); `Theme.hosting { }` for collection views that aren't screens (History list, night detail). Chosen over a loud Debug default theme, which would need a shared-kit change
- [x] Hosted leak check: a popped night detail is released with its view model
- [x] CI: pull requests build and fully test the reference brand (SleepGuard) and run every other brand's bootstrap test; nightly, manual and brand-touching pull requests (`Apps/`, `Tuist/`, `Project.swift`, AppShell) cover every brand; SwiftPM caches keyed on the lockfiles. `run-tests.sh` gained `REFERENCE_BRAND`

**Notes:**
- **Changed from the plan:** the package lane stays on every pull request (it is where the package tests run; moving it nightly would lose them), and derived data isn't cached (fragile across Xcode updates). The workflow is valid YAML; it is only exercised on GitHub.
- Locally, the in-app lane with a reference brand: about 50 s instead of about 2½ min.
- Flake seen once: `PlayerInAppTests.playsAnEpisodeAndStopsOnClose` timed out (60 s) in Dawn's full run; it passed alone twice (19 s) and in a full Dawn rerun. It plays real audio on the simulator; watch it in CI.
- Branch `feature/f13/t14-structural-checks`

### F13-T8 — Typed composition

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] `AppComposition(brand:)` owns its own container with the brand registered before anything resolves; the app never uses `Container.shared` (layering now bans it)
- [x] Flows, `NightDetailNavigation` and `MainTabCoordinator` take exactly what they use; `AppComposition` builds them. Screen factories stay composition code
- [x] `try!` replaced by a `fatalError` with the reason; the brand default's message points at `AppComposition`
- [x] `BrandBootstrapTests` resolves all 32 registrations by name and checks the list against the `Factory` declarations in the source
- [x] ADR 0009

**Notes:**
- Registrations are `.cached` (once per container) instead of `.singleton` (once per process), so two compositions never share objects.
- In-app tests reach the running app through `AppShell.launched` (main-actor, weak); the app never reads it.
- Kept Factory under the composition: a fully hand-written graph would be ~30 properties for the same result; the bootstrap test is the guard (see the ADR's limits).
- Branch `feature/f13/t8-typed-composition`

### F13-T10 — Split `RecordingFlow`

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] `InterrupterSettingsNavigation`: the interrupter's settings, sound picker and recorder sheets; one task at a time, the one before cancelled (the reassigned `interrupterTask` used to leak; tested)
- [x] `NightLifecycle`: the start delay's warm microphone and notification, the screen kept on, the battery watch (tested directly: cancel cools down, the capture is handed over once, the screen turns off once, the 2% line)
- [x] `RecordingFlow` only sequences the steps: 248 → 154 lines; its tests unchanged except for the interrupter's task

**Notes:**
- Branch `feature/f13/t10-recording-flow-split`

### F13-T11 — Atomic day delete; dynamic chrome

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] Port `delete(ids:)`: one write, all or none (an unknown id deletes none; the SwiftData store rolls back a failed save). In the port contracts, met by the store and the fake
- [x] `DeleteSessions`: every record in one write, then the clips; a failed write keeps every night and every clip (tested). History deletes a day through it, and its failure alert says the nights are all still there (shared 0.31.0 string)
- [x] `BarItemActivity`: a bar item with one is disabled with a spinner, read as the activity's label, while it runs (tested). The report button uses it
- [x] A report that can't be made shows "Couldn't Create Report" and frees the button (tested); before, it was only logged

**Notes:**
- **Changed from the plan:** the day's delete isn't moved to a flow-owned task. With one atomic write, a screen closing mid-delete can't leave half a day; it either happened or it didn't.
- `ScreenController.swift` went over the 200-line view limit; `Theme.hosting` and `ThemedScreen` moved to `ThemedHosting.swift`.
- Simulator check of the spinner skipped: the PDF is made in well under a second, so the state is covered by the tests instead.
- Branch `feature/f13/t11-day-delete-chrome`

### F13-T12 — Deep links

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] `AppRoute` parses `<scheme>://start`, `session/<id>`, `last7nights` (SleepGuard's widget paths); unknown links are ignored
- [x] The scene delegate hands over the launch link (`connectionOptions.urlContexts`) and later ones (`openURLContexts`) to `AppCoordinator.open(_:)`
- [x] A night opens in Sessions (or Statistics when the brand has no Sessions tab), from the tab's root; a night that's gone changes nothing; Last 7 Nights opens from Statistics' root; start opens the recording flow
- [x] While busy (launching, the onboarding, a night recording, a sheet up), a link waits and opens when the app is free (after the briefing or the night closes); "start" during a night is dropped; links live in memory only
- [x] Tests: parsing, every route, waiting and dropping (9)

**Notes:**
- Simulator: `simctl openurl` reached the app, but iOS's "Open in SleepGuard?" prompt couldn't be tapped (the simulator's input connection failed twice), so the on-device routing is covered by the tests, not seen.
- Branch `feature/f13/t12-deep-links`

### F13-T15 — Docs and close-out

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] ADRs 0010 (stored nights), 0011 (detection input), 0012 (links); 0009 came with T8
- [x] `ARCHITECTURE.md` current (0.31.0, counts, launch and links, 20 Hz capture, rules, tests, ADRs), on top of the owner's two renames (owner's choice to include them)
- [x] README counts, pinned version, the comparison row (from `COMPARISON.md`), shared test count, CI
- [x] `AGENTS.md` (then `CLAUDE.md`, body copied): composition root, targeted dismiss, links, cached scope, contracts, four brands, CI; `CODING_WORKFLOW.md`: four brands
- [x] Feature doc, Roadmap, trackers, session fragment

**Notes:**
- Branch `feature/f13/t15-docs`
