
### Completed
- F2-T4: `SleepPersistence` — `SessionRecord`/`EventRecord`, versioned schema V1 with migration plan, `SwiftDataSessionStore` (`@ModelActor`), record ↔ domain mapping, `FileSessionStore`, public factories.

### Technical Details
- Records never leave the store actor; callers get `Sendable` values. This is what removes SleepGuard's relationship-faulting workarounds (cached score fields, delete ordering, fault touching).
- Save = insert-or-update by id, events replaced wholesale; delete cascades.
- No unique constraint on ids (CloudKit-compatible); the actor serializes writes.
- Enums stored as raw strings; unknown values decode to safe defaults.
- `SessionRepository.session(id:)` now documents events in time order (SwiftData doesn't keep relationship order).

### Build Status
- `SleepPersistenceTests`: 9 passed, standalone, on the simulator.
- Full `run-tests.sh`: all lanes pass (Core 52, Adapters 9, Presentation 11, AppShell 7, hosted 4 × 3 brands). Layering, view size, strings, format: pass.

### Next Session
- F2-T5: Debug seeder and wiring the store into `AppShell`.
