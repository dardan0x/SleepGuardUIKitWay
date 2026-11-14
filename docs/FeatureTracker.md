# SleepGuardUIKitWay — Feature Tracker

> Updated by the AI after every task. This is the source of truth for project state.

Last updated: 2026-11-14

---

## Dashboard

| Metric | Count |
|--------|-------|
| Features | 10 |
| Done | 0 |
| In Progress | 2 |
| Backlog | 8 |
| Blocked | 0 |
| — | — |
| Total Tasks | 49 |
| Tasks Done | 7 |
| Tasks In Progress | 0 |
| Tasks Blocked | 0 |
| Tasks Backlog | 42 |
| — | — |
| **Progress** | **14%** |

## Features

| ID | Feature | Priority | Status | Tasks | Progress | File |
|----|---------|----------|--------|-------|----------|------|
| F0 | Shared repo | P0 | In Progress | 5/5 (app side pending F1) | ██████████ 100% | [tracker](trackers/f0-shared-repo.md) |
| F1 | Foundation | P0 | In Progress | 2/8 | ███░░░░░░░ 25% | [tracker](trackers/f1-foundation.md) |
| F2 | Domain and persistence | P0 | Backlog | 0/5 | ░░░░░░░░░░ 0% | [tracker](trackers/f2-domain-persistence.md) |
| F3 | History → Session Detail | P0 | Backlog | 0/5 | ░░░░░░░░░░ 0% | [tracker](trackers/f3-history-session-detail.md) |
| F4 | Statistics | P1 | Backlog | 0/4 | ░░░░░░░░░░ 0% | [tracker](trackers/f4-statistics.md) |
| F5 | Clip playback | P1 | Backlog | 0/3 | ░░░░░░░░░░ 0% | [tracker](trackers/f5-clip-playback.md) |
| F6 | Design kit adoption in SleepGuard | P2 | Backlog | 0/3 | ░░░░░░░░░░ 0% | [tracker](trackers/f6-design-kit-adoption.md) |
| F7 | Recording and detection | P1 | Backlog | 0/6 | ░░░░░░░░░░ 0% | [tracker](trackers/f7-recording-detection.md) |
| F8 | Remaining features | P2 | Backlog | 0/6 | ░░░░░░░░░░ 0% | [tracker](trackers/f8-remaining-features.md) |
| F9 | Showcase polish | P2 | Backlog | 0/4 | ░░░░░░░░░░ 0% | [tracker](trackers/f9-showcase-polish.md) |

## Currently Active

- **F1-T3** — Package skeletons with Swift 6 settings.

## Up Next

1. **F1-T4** — `SleepGuardDesignKit` in the shared repo.
2. **F1-T5** — `ScreenKit`.

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
| 2026-11-14 | F1-T2 | Completed | Tuist 4.55.5 project; `SleepGuard`, `SleepGuardLite`, `Nocturne` build and launch with their own identity, colours, icons, entitlements. Branch `feature/f1/t2-tuist-project` |
| 2026-11-14 | F1-T1 | Completed | Repo docs: `AGENTS.md`, `CLAUDE.md`, architecture notes, ADRs 0001–0004, roadmap, trackers, workflow, session log |
