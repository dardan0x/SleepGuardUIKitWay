# SleepGuardUIKitWay — Feature Tracker

> Updated by the AI after every task. This is the source of truth for project state.

Last updated: 2026-11-26

---

## Dashboard

| Metric | Count |
|--------|-------|
| Features | 14 |
| Done | 12 |
| In Progress | 2 |
| Backlog | 0 |
| Blocked | 0 |
| — | — |
| Total Tasks | 85 |
| Tasks Done | 84 |
| Tasks In Progress | 1 |
| Tasks Blocked | 0 |
| Tasks Backlog | 0 |
| — | — |
| **Progress** | **99%** |

## Features

| ID | Feature | Priority | Status | Tasks | Progress | File |
|----|---------|----------|--------|-------|----------|------|
| F0 | Shared repo | P0 | In Progress | 6/6 (shared CI doesn't build this app yet) | ██████████ 100% | [tracker](trackers/f0-shared-repo.md) |
| F1 | Foundation | P0 | Done | 8/8 | ██████████ 100% | [tracker](trackers/f1-foundation.md) |
| F2 | Domain and persistence | P0 | Done | 5/5 | ██████████ 100% | [tracker](trackers/f2-domain-persistence.md) |
| F3 | History → Session Detail | P0 | Done | 5/5 | ██████████ 100% | [tracker](trackers/f3-history-session-detail.md) |
| F4 | Statistics | P1 | Done | 5/5 | ██████████ 100% | [tracker](trackers/f4-statistics.md) |
| F5 | Clip playback | P1 | Done | 5/5 | ██████████ 100% | [tracker](trackers/f5-clip-playback.md) |
| F6 | Design kit adoption in SleepGuard | P2 | Done (bg-card open) | 4/4 | ██████████ 100% | [tracker](trackers/f6-design-kit-adoption.md) |
| F7 | Recording and detection | P1 | Done (device check open) | 7/7 | ██████████ 100% | [tracker](trackers/f7-recording-detection.md) |
| F10 | Shared screen content | P1 | Done | 7/7 | ██████████ 100% | [tracker](trackers/f10-shared-screen-content.md) |
| F8 | Remaining features | P2 | Done (device checks open) | 6/6 | ██████████ 100% | [tracker](trackers/f8-remaining-features.md) |
| F9 | Showcase polish | P2 | In Progress (T4: screenshots after the UI polish) | 3/4 | ████████░░ 75% | [tracker](trackers/f9-showcase-polish.md) |
| F11 | UIKit screen containers | P2 | Done | 1/1 | ██████████ 100% | [tracker](trackers/f11-uikit-screen-containers.md) |
| F12 | View models and factories | P2 | Done | 1/1 | ██████████ 100% | [tracker](trackers/f12-view-models.md) |
| F13 | Architecture review fixes | P0/P1 | Done | 21/21 | ██████████ 100% | [tracker](trackers/f13-architecture-review.md) |

## Currently Active

- **F13 device check** — one real night: 20 Hz cadence, a call as a gap, resume after a call, thermal logs.
- **F9-T4** — README written; the brands' screenshots wait for the UI polish.
- **F8 device checks** — Apple Health permission and writing, real sleep stages from an Apple Watch night, the start delay's notification and warm-up with the screen locked, raw audio on a real night, a Snore Interrupter melody with the microphone resuming after it, the onboarding's permission prompts on a fresh install, a morning briefing and a PDF report.
- **F7 device check** — one short night on a phone (Debug saves after 2 min): microphone, locked screen, clips, recovery after a kill.

## Up Next

1. **UI polish**, then the brands' screenshots in the README (finishes F9-T4).
2. **F0** — Shared CI also builds SleepGuardUIKitWay (the open F0-T5 item).

## Blockers

| Task | Blocked by | Needs |
|------|-----------|-------|
| — | — | — |

## Activity Log

| Date | Task | Event | Notes |
|------|------|-------|-------|
| 2026-11-26 | F13-T21 | Completed | Close-out: ADR 0013 and the docs. Branch `feature/f13/t21-close-out` |
| 2026-11-26 | F13-T20 | Completed | Shared 0.36.0: SleepStore's records and schema behind the repository. Branch `feature/f13/t20-shared-store` |
| 2026-11-26 | F13-T19 | Completed | Shared 0.35.0: SleepAudioKit behind the audio ports. Branch `feature/f13/t19-shared-audio` |
| 2026-11-26 | F13-T18 | Completed | Shared 0.34.0: logging, classifier, sample nights, storage layout, file stores, storage sweep and start notification are the shared ones. Branch `feature/f13/t18-shared-small-pieces` |
| 2026-11-26 | F13-T17 | Completed | Shared 0.33.0: `AppPreferences` is SleepCore's `SleepPreferences`; the UserDefaults store wraps `PreferencesDefaults`, the same code as SleepGuard. Branch `feature/f13/t17-shared-preferences` |
| 2026-11-26 | F13-T16 | Completed | Shared 0.32.0: HealthKit and the raw log are shared behaviour (`HealthKitSleep`, `RawLogFile`) wrapped by this app's adapters, as in SleepGuard. Branch `feature/f13/t16-shared-healthkit-rawlog` |
| 2026-11-26 | F13-T15 | Completed | ADRs 0010–0012, architecture doc, README, AGENTS/CLAUDE, workflow, feature doc. F13 done; the owner merges `feature/f13-architecture-review` into main. Branch `feature/f13/t15-docs` |
| 2026-11-26 | F13-T12 | Completed | Deep links: `AppRoute` (start, session, last 7 nights) from the scene delegate to `AppCoordinator`, held while busy, dropped when meaningless. Branch `feature/f13/t12-deep-links` |
| 2026-11-26 | F13-T11 | Completed | A day's nights deleted in one write (`delete(ids:)`, `DeleteSessions`), all or none; bar items with an activity (report button busy state); a failed report shows an alert. Branch `feature/f13/t11-day-delete-chrome` |
| 2026-11-26 | F13-T10 | Completed | `RecordingFlow` split into `InterrupterSettingsNavigation` and `NightLifecycle` (248 → 154 lines); the interrupter's task no longer leaks. Branch `feature/f13/t10-recording-flow-split` |
| 2026-11-26 | F13-T8 | Completed | `AppComposition` per brand (own container, no `Container.shared`); flows take what they use; per-container scope; bootstrap test resolves all 32 registrations and checks the list against the source; ADR 0009. Branch `feature/f13/t8-typed-composition` |
| 2026-11-26 | F13-T5 | Completed | Shared 0.31.0 tagged by the owner and pinned; a store that doesn't open shows only "We couldn't open your sleep data" and keeps the file. All brands build and all lanes pass on the release. Branch `feature/f13/t5-store-unavailable` |
| 2026-11-26 | F13-T14 | Completed | Screens can't present (compile error) except alerts; only ScreenKit hosts SwiftUI (layering rule 9, `Theme.hosting`); hosted leak check; CI tests one reference brand per PR, all brands nightly or when brand code changes, SwiftPM cache. Branch `feature/f13/t14-structural-checks` |
| 2026-11-26 | F13-T13 | Completed | Port contracts in `SleepDomainTestSupport`, run against every fake and adapter; `FakeSessionRepository` now returns events in time order (the one drift found). Branch `feature/f13/t13-port-contracts` |
| 2026-11-26 | F13-T9 | Completed | Navigator runs operations serially and picks presenters only when idle; targeted `dismiss(_:)` (an alert goes with its sheet); `presentAlert` waits for transitions; hosted race tests with a time limit. Branch `feature/f13/t9-navigator-races` |
| 2026-11-26 | F13-T7 | Completed | Checkpoints through a latest-wins writer task, raw log through a serial one; the sample path never waits for the disk; `stop` drains both. Branch `feature/f13/t7-off-path-writes` |
| 2026-11-26 | F13-T6 | Completed | 20 Hz decimation in `RecordingSession` (same samples as SleepGuard); interruptions reported by the adapter and sent to the engine as pause/resume (gaps left out of the score); resume without `.shouldResume` and after media-services reset; FFT only with the raw log; thermal state logged. Branch `feature/f13/t6-capture-parity` |
| 2026-11-26 | F13-T5 | In progress | Store-unavailable screen built and checked on the simulator; shared 0.31.0 pushed on a branch for the owner to merge and tag. Branch `feature/f13/t5-store-unavailable` |
| 2026-11-26 | F13-T4 | Completed | Publishing after a committed write no longer throws; every write publishes; single-writer assumption documented (cross-context observation dropped: no second writer exists). Branch `feature/f13/t4-store-observation` |
| 2026-11-26 | F13-T3 | Completed | `LoadSessionDetail` is a query; `EnrichNightWithStages` stores stages through a narrow `updateStages` (no event rewrite); a failed stage save no longer stops a night from opening. Branch `feature/f13/t3-read-only-detail` |
| 2026-11-26 | F13-T2 | Completed | Stored summaries carry their score version; `RefreshStaleSummaries` recomputes stale ones at launch in batches (summary columns only), before the briefing. A pre-change store with 14 nights opened and was refreshed on the simulator. Branch `feature/f13/t2-score-version` |
| 2026-11-26 | F13-T1 | Completed | Shared 0.30.0 pinned with the compatibility changes (interruption gaps recorded, gap banner melody-only); `SaveRules` from the composition replaces `Night.minimumSaveDuration`. All brands build and all lanes pass on the release. Branch `feature/f13/t1-shared-0-30-save-rules` |
| 2026-11-26 | F13 | Planned | Architecture review fixes planned with the owner: 15 tasks, every concern checked against the code first. Feature branch `feature/f13-architecture-review`, a PR per task |
| 2026-11-18 | F12-T1 | Completed | A view model for every screen, 19 for 21 (ADR 0008; no UI imports and one per screen, both checked; no `@ObservationIgnored`), tested with fakes; controllers only draw, forward and present; composers renamed factories and build dependencies, view model, controller. `FakeMelodyRecorder` fixed to keep its take at the limit. Planned with the owner as one task. Branch `feature/f12/t1-view-models` |
| 2026-11-18 | F11-T1 | Completed | Shared 0.28.0 tagged by the owner and pinned (`bump-shared.sh`); all lanes pass and all four brands build on the release (`TUIST_SHARED_RELEASE=1`). F11 done. Branch `feature/f11/t1-uikit-screen-containers` |
| 2026-11-18 | F11-T1 | In progress | Every screen a UIKit `ScreenController` hosting the shared content (ADR 0007; scope widened by the owner from three screens to all): History collection view, Onboarding page view controller, Session Detail compositional layout with a segmented filter, the rest in hosted children or `ContentListController`; `HostingScreen` removed; shared pieces made public on a local branch (0.28.0). All brands build, all lanes pass against the local shared repo. Waits for the release. Branch `feature/f11/t1-uikit-screen-containers` |
| 2026-11-18 | F11 | Planned | UIKit screen containers planned with the owner as one task: History (collection view), Onboarding (page view controller), Session Detail (compositional collection view) host shared content via `UIHostingConfiguration`; features may use UIKit, navigation stays with coordinators (ADR 0007 to come) |
| 2026-11-18 | F9-T4 | In progress | README rewritten (brands, how to run, where to look first, layout, status); screenshots deferred until the UI polish. Branch `feature/f9/t4-readme` |
| 2026-11-17 | F9-T3 | Completed | `docs/COMPARISON.md`: a night's detail in both apps, concern by concern, sizes and tests measured; honest about where SleepGuard's shape is simpler. Branch `feature/f9/t3-comparison` |
| 2026-11-17 | F9-T2 | Completed | Dawn, a fourth brand, added as the worked example in `docs/ADDING_A_BRAND.md`: one folder and one brand-list entry; the test script and CI now find brands by folder. Branch `feature/f9/t2-adding-a-brand` |
| 2026-11-17 | F9-T1 | Completed | `docs/ARCHITECTURE.md`, checked against the code: module graph, layers with sizes, a screen end to end, brands, shared repo, recording, rules and their checks, tests, ADRs. Branch `feature/f9/t1-architecture-doc` |
| 2026-11-17 | F8-T6 | Completed | Personalization: morning briefing (shared engine as values, survey with storage), profile prompt on the dashboard, PDF report and clip sharing (0.27.0). F8 done. Branch `feature/f8/t6-personalization` |
| 2026-11-17 | F8-T5 | Completed | Learn tab: the shared Learn page or its empty state (0.26.0); `BrandConfiguration.learnURL` (nil until a page exists); placeholder flow removed. Branch `feature/f8/t5-learn` |
| 2026-11-17 | F8-T2 | Completed | Onboarding on first launch (shared pages and page rules, 0.25.0): microphone and, in Health brands, Apple Health; finishing keeps the flag and can start a night; the launch waits for the preferences, so no tabs flash first. Branch `feature/f8/t2-onboarding` |
| 2026-11-17 | F8-T4 | Completed | Snore Interrupter: melody on detected snoring with the microphone paused and the gap recorded, prestart row and settings sheet, picker with preview, custom recordings, bedside note and overlay; off in Lite (`BrandConfiguration.snoreInterrupter`). Shared rules, sounds and content (0.24.0). Branch `feature/f8/t4-snore-interrupter` |
| 2026-11-17 | F8-T3 | Completed | Sleep stages from Apple Health on the night detail and the dashboard, with the info sheet; `HealthAccess` refines `SleepStagePort`, read whenever the brand has Health. Shared rules, components and content (0.23.0). Branch `feature/f8/t3-sleep-stages` |
| 2026-11-17 | F8-T1 | Completed | Settings, profile editor, start delay with countdown, storage limits (with leftover files), delete all, Apple Health sync as a brand port (ADR 0006), raw logging. Shared content and rules (0.22.0). Branch `feature/f8/t1-settings` |
| 2026-11-17 | F10-T6 | Completed | Review (nothing left to share for these screens), product lists updated in every doc, F10 feature doc. F10 done. Branch `feature/f10/t6-review` |
| 2026-11-17 | F10-T5 | Completed | Recording screens' content shared (`PrestartContent`, `BedsideClockContent`, `SessionSummaryContent`, shared 0.21.0); both apps host it, SleepGuard's melody pieces in slots. Branch `feature/f10/t5-recording-content` |
| 2026-11-16 | F10-T4b | Completed | Player content and `ClipWaveform` shared, `WaveformAccumulator` in SleepCore (shared 0.20.0); the waveform reaches this app (`ClipWaveformSource` port + `FileWaveformSource`). Branch `feature/f10/t4b-player` |
| 2026-11-16 | F10-T4a | Completed | Night detail and events grid content, SleepCore's `EventFilter` / `EventListRow` (shared 0.19.0); both apps host it. T4 split: the player and its waveform are T4b. Branch `feature/f10/t4a-night-detail` |
| 2026-11-16 | F10-T3 | Completed | Nights list content and SleepCore's `NightMonth` (shared 0.18.0); both apps host it; `HistorySections` and the History views removed. Branch `feature/f10/t3-nights-list` |
| 2026-11-16 | F10-T2 | Completed | `SleepGuardContentKit` (shared 0.17.0) with the Statistics screens' content; both apps host it; this app's 5 content views and their render tests removed. Branch `feature/f10/t2-statistics-content` |
| 2026-11-16 | F10-T1 | Completed | F10 planned with the owner: screen content moves to a new shared product, screens stay per app (ADR 0005; SleepGuard ADR 0006, F25). Rule in AGENTS/CLAUDE, layering table. Branch `feature/f10/t1-content-kit-setup` |
| 2026-11-16 | F7-T7 | Completed | Checkpoint port and file store, `RecoverInterruptedSession`, `DiscardRecording`, checkpoints from the recording actor, launch recovery, low-battery stop. F7 done (device check open); feature doc written. Feature counts corrected (were stale). Branch `feature/f7/t7-recovery` |
| 2026-11-16 | F7-T6 | Completed | `RecordingFlow` (full-screen modal from `AppCoordinator`), `CommitSession`, discard with clips, `DeviceServices`, microphone text and background audio in Info.plist; flow and hosted tests. Device night not done yet. Branch `feature/f7/t6-recording-flow` |
| 2026-11-16 | F7-T5 | Completed | Recording pieces in the kit + `Night.minimumSaveDuration` (shared 0.16.0); SleepGuard uses them. `RecordingFeature`: prestart, bedside clock (`LiveRecordingModel`), summary. Countdown moved to F8. Branch `feature/f7/t5-recording-screens` |
| 2026-11-16 | F7-T4 | Completed | `RecordingSession` actor (capture → shared `DetectionEngine` → `RecordingDraft`, 5 Hz `LiveSnapshot`); SleepGuard's characterization cases pass unchanged. Port: `closeClip` / `compressClip`, open clip survives `stop`. Branch `feature/f7/t4-recording-session` |
| 2026-11-16 | F7-T3b | Completed | Capture adapter: `AudioCapturePort`, `EngineAudioCapture` (direct tap, `.measurement`, resume), `CaptureProcessor` (the one allow-listed lock), `SoundClassifier`, `ClipCompressor`; 7 simulator tests. On shared 0.15.0. Engine not yet checked on a device. Branch `feature/f7/t3-capture` |
| 2026-11-16 | F7-T3a | Completed | Detection inputs shared (`AudioLevels`, `SpectralFeatures`, `SoundClassLabels`, shared 0.15.0); SleepGuard uses them. F6 marked done on the dashboard. Branch `feature/f7/t3-capture` |
| 2026-11-16 | F7-T1, F7-T2 | Completed | F7 planned (7 tasks, core night). Per-sample detection rules in `SleepCore` (shared 0.14.0); SleepGuard uses them. Branch `feature/f7/t1-shared-detection` |
| 2026-11-14 | — | Planned | Architecture proposal approved: `ARCHITECTURE_PLAN.md` |
| 2026-11-14 | F0-T1 | Completed | `SleepGuardShared` created; `SleepCore` and `SleepStrings` moved out of SleepGuard; SleepGuard builds and all 8 package suites pass against it. SleepGuard commit `0aa76d3`, shared commit `317ea15` |
| 2026-11-14 | F0-T2 | Completed | Store written before the move is a fixture in SleepGuard; a test opens it and decodes every moved type |
| 2026-11-14 | F0-T3 | Completed | Owner created and pushed both repos; `SleepGuardShared` made public; tag `0.1.0` |
| 2026-11-14 | F0-T4 | Completed | SleepGuard depends on `SleepGuardShared` 0.1.0 by URL; `SleepGuard.xcworkspace` overrides it with the local checkout; `bump-shared.sh` |
| 2026-11-14 | F0-T5 | Completed | Shared-repo CI (tests, strings sync, SleepGuard build); SleepGuard's `strings-sync` removed. Not yet run on GitHub |
| 2026-11-15 | F5-T5 | Completed | Player sheet from new kit components (shared 0.11.0), Play on rows and cards, Debug sample clips. F5 done. Branch `feature/f5/t5-player-sheet` |
| 2026-11-15 | F5-T4 | Completed | `EngineClipPlayer` over AVAudioEngine (SleepGuard's chain), 5 simulator tests. Branch `feature/f5/t4-audio-adapter` |
| 2026-11-15 | F5-T3 | Completed | `ClipPlayer` port, clip URLs, `FakeClipPlayer`, `ClipPlaybackModel` state owner with 13 tests. Branch `feature/f5/t3-player-port` |
| 2026-11-15 | F5-T1, F5-T2 | Completed | Playback rules (`ClipPlaylist`, `PlaybackGain`, `PlaybackEnhancement`) in `SleepCore` (shared 0.10.0); SleepGuard's controller uses them. Branch `feature/f5/t1-shared-playlist` |
| 2026-11-15 | F4-T5 | Completed | Statistics tab live: `StatisticsFlow`, composers, `NightDetailNavigation` shared with Sessions, start recording to `AppCoordinator`. F4 done. Branch `feature/f4/t5-statistics-flow` |
| 2026-11-15 | F4-T4 | Completed | Trends, Last 7 Nights, Calendar screens from new kit components (shared 0.9.0). Branch `feature/f4/t4-trends-calendar-last7` |
| 2026-11-14 | F4-T3 | Completed | `StatisticsFeature` dashboard (live, empty state); week-strip rule and snoring level moved to shared (0.8.0), SleepGuard uses them. Branch `feature/f4/t3-dashboard` |
| 2026-11-14 | F4-T1, F4-T2 | Completed | Statistics rules moved to `SleepCore` (shared 0.7.0) with SleepGuard's test cases; SleepGuard's Statistics uses them (its branch `feature/shared/f4-t2-shared-statistics`). Branch `feature/f4/t1-shared-statistics` |
| 2026-11-14 | F3-T5 | Completed | Detail components moved to the shared kit (0.6.0): stats grid, timeline, banners, event row/card, score badge, night row; UIKitWay's copies removed; timeline and banners on the detail. F3 done. Branch `feature/f3/t5-detail-components` |
| 2026-11-14 | F3-T4 | Completed | Events sheet: card grid for the current filter, UIKit sheet (medium/large) from `HistoryFlow`, close dismisses. Branch `feature/f3/t4-events-sheet` |
| 2026-11-14 | F6 | Planned | Design kit adoption detailed (4 tasks) and mirrored in SleepGuard as F24; no longer waits for F4. F3-T5 widened: event row, score badge, night row also move to the kit. Rule: values-only views go in the kit |
| 2026-11-14 | F3-T3 | Completed | Sessions tab live: `HistoryFlow`, composers, delete with confirmation then pop; inline list title. Shared bumped to 0.5.0. Branch `feature/f3/t3-history-flow` |
| 2026-11-14 | F3-T2 | Completed | `SessionDetailFeature`: header with gauge and stats, category filter, episode-collapsed event rows; 5 tests. Branch `feature/f3/t2-session-detail` |
| 2026-11-14 | F3-T1 | Completed | `HistoryFeature` (first feature module): live list by month and day, expand multi-night days, swipe to delete; 4 tests. Branch `feature/f3/t1-history` |
| 2026-11-14 | F0-T6 | Completed | Night entities and rules moved to `SleepCore` (`Night`, `NightEvent`, `NightEpisode`, `NightSummary`); this app and SleepGuard both use them; SleepGuard's tests unchanged and green. Needs shared 0.4.0 |
| 2026-11-14 | F2-T5 | Completed | Store wired into the shell in each brand's app group; 14 deterministic Debug sample nights. **F2 done.** Branch `feature/f2/t5-seeder` |
| 2026-11-14 | F2-T4 | Completed | SwiftData store as a `@ModelActor` (records never leave it), versioned schema, mappers, observation, file store; 9 tests on real SwiftData. Branch `feature/f2/t4-swiftdata` |
| 2026-11-14 | F2-T3 | Completed | Ports (`SessionRepository`, `SessionFileStore`, `SleepStagePort`), `DeleteSession`, `LoadSessionDetail`, actor fakes; 52 domain tests. Branch `feature/f2/t3-ports` |
| 2026-11-14 | F2-T1, F2-T2 | Completed | Domain entities and policies; SleepGuard's episode/stats/score cases ported (42 tests). Needs shared 0.3.0 (`Equatable` values). Branch `feature/f2/t1-entities` |
| 2026-11-14 | F1-T8 | Completed | Checks (layering, view size, strings), `run-tests.sh` (3 lanes, isolated package builds), `bump-shared.sh`, PR CI. **F1 done.** Branch `feature/f1/t8-scripts-ci` |
| 2026-11-14 | F1-T7 | Completed | Three distinct brands: themes, tab sets, Lite without `SleepHealth`; per-brand hosted tests (4 each); themed bar fonts. Branch `feature/f1/t7-brands` |
| 2026-11-14 | F1-T6 | Completed | `AppShell`: brand contract, bootstrap, container, app and tab coordinators, themed bars, placeholder flows; 6 package tests + 2 in-app presentation tests. Branch `feature/f1/t6-appshell` |
| 2026-11-14 | F1-T5 | Completed | `ScreenKit`: `HostingScreen`, `ScreenChrome`, `NavigationControllerNavigator` (waits out running transitions); 11 tests; packages on shared 0.2.0. Containment helper deferred; real presenting checked in F1-T6. Branch `feature/f1/t5-screenkit` |
| 2026-11-14 | F1-T4 | Completed | `SleepGuardDesignKit` in the shared repo: `Theme` value in the environment, 10 components ported from SleepGuard, render tests in two themes. Branch `feature/f1/t4-design-kit` (both repos) |
| 2026-11-14 | F1-T3 | Completed | `Core`, `Adapters`, `Presentation`, `AppShell` packages; shared 0.1.0 with local override by default; found that undeclared imports compile inside the app workspace. Branch `feature/f1/t3-package-skeletons` |
| 2026-11-14 | F1-T2 | Completed | Tuist 4.55.5 project; `SleepGuard`, `SleepGuardLite`, `Nocturne` build and launch with their own identity, colours, icons, entitlements. Branch `feature/f1/t2-tuist-project` |
| 2026-11-14 | F1-T1 | Completed | Repo docs: `AGENTS.md`, `CLAUDE.md`, architecture notes, ADRs 0001–0004, roadmap, trackers, workflow, session log |
