# F2 — Domain and persistence

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P0 |
| **Milestone** | M1 |
| **Blocked By** | — |
| **Started** | 2026-11-14 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The domain model of a night exists as plain values with its rules tested on macOS, and it can be stored and observed through a repository port backed by SwiftData. Debug builds can seed sample nights, so screens have data before recording exists.

## Tasks

| ID | Task | Type | Status | Depends On | Module | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F2-T1 | Entities and values: `SleepSession`, `SnoreEvent`, `SessionSummary`, `SnoringEpisode` | Domain | Done | F1-T3 | SleepDomain | `Sendable` structs; no framework imports |
| F2-T2 | Policies: episode merging, snoring duration, score inputs, minimum save duration | Domain | Done | F2-T1 | SleepDomain (or `SleepCore` if SleepGuard adopts them) | Same results as SleepGuard's `SessionStatsTests` / `SnoringEpisodeTests` cases |
| F2-T3 | Ports and use cases: `SessionRepository`, `SessionFileStore`, `DeleteSession`, `LoadSessionDetail`; fakes | Domain | Done | F2-T1 | SleepDomain, TestSupport | Use-case tests with fakes on macOS |
| F2-T4 | SwiftData adapter: records, `@ModelActor` store, mappers, `observeSummaries()` | Adapter | Done | F2-T3 | SleepPersistence | Round-trip and observation tests against an in-memory store; records never leave the actor |
| F2-T5 | Debug sample-night seeder | Tooling | Backlog | F2-T4 | SleepPersistence, AppShell | Each brand launches with seeded nights in Debug |

## Task Details

### F2-T1 — Entities (done 2026-11-14)
- [x] `SleepSession` (finished night: events, gaps, stages, `EndReason`), `SnoreEvent` (span, bursts, `measuredDuration`, clip file name), `SessionSummary` (list row), `SnoringEpisode` (sorted events, aggregates)
- [x] `Sendable`, `Equatable`, `Identifiable`; Foundation + `SleepCore` only
- [x] Needs `SleepGuardShared` 0.3.0: `RecordingGap` and `SleepStageSegment` became `Equatable` there (additive; SleepGuard unaffected, checked for clashing extensions)
- Notes: spectral fields (dominant frequency, centroid, low-frequency ratio) left out until a screen needs them.

### F2-T2 — Policies (done 2026-11-14)
- [x] `SnoringEpisodes`: 5-minute merge, 3 s display filter, playback events for a row
- [x] `SleepSession` metrics: `snoringDuration` (with SleepGuard's gap rule), sleep talking, `eventCount`, `stageStats`, `scoreInputs`, `score(using:)`, `summary(using:)`
- [x] SleepGuard's `SnoringEpisodeTests`, `SessionStatsTests` and `SleepScoreTests` cases ported with the same numbers: 42 domain tests pass on macOS
- Moved out: minimum save duration → F7 (saving a night); timeline segments → F3-T5 (the timeline).

### F2-T3 — Ports and use cases (done 2026-11-14)
- [x] Ports: `SessionRepository` (save with summary, load, delete, `observeSummaries()`), `SessionFileStore`, `SleepStagePort`; `SessionError.notFound`
- [x] `DeleteSession`: record first, then clips (a failed delete keeps the clips)
- [x] `LoadSessionDetail`: adds missing stages and re-saves with the new score; a failing stage source still opens the night
- [x] Fakes (actors) in `SleepDomainTestSupport`: `FakeSessionRepository` (with observation), `FakeSessionFileStore`, `FakeSleepStagePort`
- [x] Use-case tests with fakes on macOS: 52 domain tests pass
- Notes: `SleepStagePort` added here because loading a night needs it (no adapter until F8; brands without HealthKit get a port that returns none). `observeSummaries()` is `async` so actor-based stores can implement it.

### F2-T4 — SwiftData adapter (done 2026-11-14)
- [x] `SessionRecord` / `EventRecord` (internal), versioned schema V1 + migration plan from the start
- [x] `SwiftDataSessionStore` as a `@ModelActor`: records never leave it; save is insert-or-update by id; events replaced wholesale; cascade delete
- [x] Mappers both ways; events returned in time order (now part of the port's contract); unknown stored enum values read as `.other` / `.quiet` / `.stopped`
- [x] `observeSummaries()`: current list, then the new list after each write, newest first
- [x] `FileSessionStore`: removes named files, ignores missing ones, refuses names that leave its directory
- [x] Public surface: `SleepPersistence.makeSessionRepository(storeURL:)`, `makeSessionFileStore(directory:)`
- [x] 9 tests against real SwiftData (in memory, and on disk for reopening), run standalone on the simulator
- Notes: no `@Attribute(.unique)` on ids (keeps CloudKit possible; the actor serializes saves). Not wired into `AppShell` yet: the first consumer is the seeder (T5) and the History screen (F3).

## Notes

- **Decision (F2-T2):** the episode and duration rules live in `SleepDomain`, not `SleepCore`. They operate on this app's entities; moving them to `SleepCore` would mean a shared event value type and SleepGuard mapping its `@Model` classes to it, a refactor of the working app with no feature gained today. The cost is duplication: the rules exist in both apps, kept identical by the ported tests. Revisit if they need to change.
- Fresh store: no migration from SleepGuard's data.
