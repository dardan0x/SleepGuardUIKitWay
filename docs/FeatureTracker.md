# SleepGuardUIKitWay — Feature Tracker

> Updated by the AI after every task. This is the source of truth for project state.

Last updated: 2026-11-14

---

## Dashboard

| Metric | Count |
|--------|-------|
| Features | 11 |
| Done | 9 |
| In Progress | 2 |
| Backlog | 0 |
| Blocked | 0 |
| — | — |
| Total Tasks | 62 |
| Tasks Done | 60 |
| Tasks In Progress | 0 |
| Tasks Blocked | 0 |
| Tasks Backlog | 2 |
| — | — |
| **Progress** | **97%** |

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
| F9 | Showcase polish | P2 | In Progress | 2/4 | █████░░░░░ 50% | [tracker](trackers/f9-showcase-polish.md) |

## Currently Active

- **F8-T1 / F8-T3 / F8-T4 device checks** — Apple Health permission and writing, real sleep stages from an Apple Watch night, the start delay's notification and warm-up with the screen locked, raw audio on a real night, a Snore Interrupter melody with the microphone resuming after it, the onboarding's permission prompts on a fresh install.
- **F7 device check** — one short night on a phone (Debug saves after 2 min): microphone, locked screen, clips, recovery after a kill.

## Up Next

1. **F9-T3** — Comparison with SleepGuard. Then T4, the README.
2. **F0** — Shared CI also builds SleepGuardUIKitWay (the open F0-T5 item).

## Blockers

| Task | Blocked by | Needs |
|------|-----------|-------|
| — | — | — |

## Activity Log

| Date | Task | Event | Notes |
|------|------|-------|-------|
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
