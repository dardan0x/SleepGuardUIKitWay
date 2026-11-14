# SleepGuardUIKitWay — Feature Tracker

> Updated by the AI after every task. This is the source of truth for project state.

Last updated: 2026-11-14

---

## Dashboard

| Metric | Count |
|--------|-------|
| Features | 10 |
| Done | 2 |
| In Progress | 1 |
| Backlog | 7 |
| Blocked | 0 |
| — | — |
| Total Tasks | 50 |
| Tasks Done | 19 |
| Tasks In Progress | 0 |
| Tasks Blocked | 0 |
| Tasks Backlog | 31 |
| — | — |
| **Progress** | **38%** |

## Features

| ID | Feature | Priority | Status | Tasks | Progress | File |
|----|---------|----------|--------|-------|----------|------|
| F0 | Shared repo | P0 | In Progress | 6/6 (0.4.0 release pending) | ██████████ 100% | [tracker](trackers/f0-shared-repo.md) |
| F1 | Foundation | P0 | Done | 8/8 | ██████████ 100% | [tracker](trackers/f1-foundation.md) |
| F2 | Domain and persistence | P0 | Done | 5/5 | ██████████ 100% | [tracker](trackers/f2-domain-persistence.md) |
| F3 | History → Session Detail | P0 | Backlog | 0/5 | ░░░░░░░░░░ 0% | [tracker](trackers/f3-history-session-detail.md) |
| F4 | Statistics | P1 | Backlog | 0/4 | ░░░░░░░░░░ 0% | [tracker](trackers/f4-statistics.md) |
| F5 | Clip playback | P1 | Backlog | 0/3 | ░░░░░░░░░░ 0% | [tracker](trackers/f5-clip-playback.md) |
| F6 | Design kit adoption in SleepGuard | P2 | Backlog | 0/3 | ░░░░░░░░░░ 0% | [tracker](trackers/f6-design-kit-adoption.md) |
| F7 | Recording and detection | P1 | Backlog | 0/6 | ░░░░░░░░░░ 0% | [tracker](trackers/f7-recording-detection.md) |
| F8 | Remaining features | P2 | Backlog | 0/6 | ░░░░░░░░░░ 0% | [tracker](trackers/f8-remaining-features.md) |
| F9 | Showcase polish | P2 | Backlog | 0/4 | ░░░░░░░░░░ 0% | [tracker](trackers/f9-showcase-polish.md) |

## Currently Active

- None. F2 is complete: merge `feature/f2-domain-persistence` into `main`, then F3.

## Up Next

1. **F3-T1** — History screen (branch `feature/f3-history-session-detail` from `main`).
2. **F0** — Shared CI also builds SleepGuardUIKitWay (the open F0-T5 item).

## Blockers

| Task | Blocked by | Needs |
|------|-----------|-------|
| — | — | — |

## Activity Log

| Date | Task | Event | Notes |
|------|------|-------|-------|
| 2026-11-14 | — | Planned | Architecture proposal approved: `ARCHITECTURE_PLAN.md` |
| 2026-11-14 | F0-T1 | Completed | `SleepGuardShared` created; `SleepCore` and `SleepStrings` moved out of SleepGuard; SleepGuard builds and all 8 package suites pass against it. SleepGuard commit `0aa76d3`, shared commit `317ea15` |
| 2026-11-14 | F0-T2 | Completed | Store written before the move is a fixture in SleepGuard; a test opens it and decodes every moved type |
| 2026-11-14 | F0-T3 | Completed | Owner created and pushed both repos; `SleepGuardShared` made public; tag `0.1.0` |
| 2026-11-14 | F0-T4 | Completed | SleepGuard depends on `SleepGuardShared` 0.1.0 by URL; `SleepGuard.xcworkspace` overrides it with the local checkout; `bump-shared.sh` |
| 2026-11-14 | F0-T5 | Completed | Shared-repo CI (tests, strings sync, SleepGuard build); SleepGuard's `strings-sync` removed. Not yet run on GitHub |
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
