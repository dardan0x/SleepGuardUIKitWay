# F2 — Domain and persistence

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P0 |
| **Milestone** | M1 |
| **Blocked By** | F1 |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The domain model of a night exists as plain values with its rules tested on macOS, and it can be stored and observed through a repository port backed by SwiftData. Debug builds can seed sample nights, so screens have data before recording exists.

## Tasks

| ID | Task | Type | Status | Depends On | Module | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F2-T1 | Entities and values: `SleepSession`, `SnoreEvent`, `SessionSummary`, `SnoringEpisode` | Domain | Backlog | F1-T3 | SleepDomain | `Sendable` structs; no framework imports |
| F2-T2 | Policies: episode merging, snoring duration, score inputs, minimum save duration | Domain | Backlog | F2-T1 | SleepDomain (or `SleepCore` if SleepGuard adopts them) | Same results as SleepGuard's `SessionStatsTests` / `SnoringEpisodeTests` cases |
| F2-T3 | Ports and use cases: `SessionRepository`, `SessionFileStore`, `DeleteSession`, `LoadSessionDetail`; fakes | Domain | Backlog | F2-T1 | SleepDomain, TestSupport | Use-case tests with fakes on macOS |
| F2-T4 | SwiftData adapter: records, `@ModelActor` store, mappers, `observeSummaries()` | Adapter | Backlog | F2-T3 | SleepPersistence | Round-trip and observation tests against an in-memory store; records never leave the actor |
| F2-T5 | Debug sample-night seeder | Tooling | Backlog | F2-T4 | SleepPersistence, AppShell | Each brand launches with seeded nights in Debug |

## Notes

- Decide in F2-T2 whether the episode and duration rules go straight into `SleepCore` so SleepGuard can call them too. That edits SleepGuard and needs its goldens and tests green.
- Fresh store: no migration from SleepGuard's data.
