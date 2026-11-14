# F2 — Domain and persistence

A night exists as plain values with its rules tested on macOS, is stored in SwiftData behind an actor, and can be observed as a live list. Debug builds start with 14 sample nights. No screen shows them yet (F3).

## Files

| File | Purpose |
|------|---------|
| `Packages/Core/Sources/SleepDomain/Entities/{SleepSession,SnoreEvent,SessionSummary,SnoringEpisode}.swift` | The night as `Sendable`, `Equatable` values |
| `Packages/Core/Sources/SleepDomain/Policies/SnoringEpisodes.swift` | Episode grouping, display filter, playback events |
| `Packages/Core/Sources/SleepDomain/Policies/SleepSession+Metrics.swift` | Snoring duration, sleep talking, event count, stage stats, score inputs, score, summary |
| `Packages/Core/Sources/SleepDomain/Ports/{SessionRepository,SessionFileStore,SleepStagePort}.swift` | What the domain needs from storage and HealthKit |
| `Packages/Core/Sources/SleepDomain/UseCases/{DeleteSession,LoadSessionDetail}.swift` | Delete a night with its clips; open a night, adding stages |
| `Packages/Core/Sources/SleepDomainTestSupport/Fake*.swift` | Actor fakes for every port |
| `Packages/Adapters/Sources/SleepPersistence/Records/*` | `SessionRecord`, `EventRecord`, versioned schema, mapping (internal) |
| `Packages/Adapters/Sources/SleepPersistence/Store/{SwiftDataSessionStore,FileSessionStore}.swift` | `@ModelActor` repository; clip file store |
| `Packages/Adapters/Sources/SleepPersistence/SleepPersistence.swift` | Public factories |
| `Packages/AppShell/Sources/AppShell/Storage/StorageLocation.swift` | App group or Application Support |
| `Packages/AppShell/Sources/AppShell/Container+AppShell.swift` | `storageLocation`, `sessionRepository`, `sessionFileStore` |
| `Packages/AppShell/Sources/AppShell/Debug/SampleNights.swift` | Deterministic Debug nights |
| `../SleepGuardShared` 0.3.0 | `RecordingGap`, `SleepStageSegment` became `Equatable` |

## Routes

None: no screens in F2.

## State

| State | Where | Lifetime |
|-------|-------|----------|
| Nights, events, summaries | `SwiftDataSessionStore` (records on its actor only) | On disk, in the brand's app group |
| Clips | `Clips/` next to the store | On disk |
| Summary observers | The store's continuation list | While a caller iterates |
| Sample-night seeding | `AppCoordinator.seeding` task (Debug) | Launch |

## Edge cases

- **Store can't open:** in-memory store for that launch, fault logged, file untouched.
- **App group unavailable:** Application Support.
- **Unknown stored enum values** (newer version): read as `.other` / `.quiet` / `.stopped`.
- **Event order:** SwiftData doesn't keep it; the store returns events by start time (part of the port contract).
- **Delete fails:** clips are removed only after the record, so a night never points at missing files.
- **Stage source fails:** the night opens without stages; next open retries.
- **Clip names with path components:** ignored by the file store.
- **Re-seeding:** only an empty store is seeded; real nights are never touched.

## Tasks completed

F2-T1 entities · F2-T2 policies (SleepGuard's cases ported, same numbers) · F2-T3 ports, use cases, fakes · F2-T4 SwiftData store · F2-T5 store wiring and sample nights.
