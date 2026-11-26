# ADR 0010: Stored nights: versioned scores, one writer, safe failures

- **Status:** Accepted
- **Date:** 2026-11-26
- **Task:** F13-T2, T3, T4, T5, T11 (architecture review Q9, Q34, Q37, Q38, Q55)
- **Amends:** ADR 0002 (what `SessionRepository` promises)

## Context

The review found five weaknesses in how nights are stored:
- A stored summary had no record of which score formula made it. Shared 0.30.0 changed the formula (calls left out of the score), so every stored score went stale and nothing recomputed it: History and Statistics would have mixed two formulas.
- Opening a night saved it again (all events rewritten) when sleep stages arrived, and a failed save failed the open.
- Observers were told about writes by the store itself after each write; a failed re-read made a committed write throw, and `removeClips` told nobody.
- When the database couldn't open, the app quietly ran on an in-memory store: nights recorded that launch were lost.
- Deleting a day looped over its nights; a failure midway left half a day.

## Decision

- **Versioned summaries.** `SessionRecord.scoreVersion` (additive; "" means stale) stores SleepCore's `SleepScore.cacheVersion(for:)`. At launch, `RefreshStaleSummaries` recomputes stale nights in batches of 20 and writes summary columns only (`updateSummaries`), before the briefing reads them.
- **Reads don't write.** `LoadSessionDetail` is a query. `EnrichNightWithStages` stores stages through a narrow `updateStages` (stages and summary, never events); if that fails the screen still shows them and the next open tries again.
- **One writer.** The store actor is the database's only writer (one per composition; no widget, extension or sync opens it), so its explicit publishing sees every write. Publishing happens after a committed save and never throws. A second writer would need persistent-history observation first.
- **A store that won't open stops the app.** `StoreOpening` says whether the file opened; if not, `AppCoordinator` shows only "We couldn't open your sleep data" (shared content) and nothing runs on the in-memory store. The file is never touched.
- **All or none.** `delete(ids:)` removes a day's nights in one save (rolled back on failure); `DeleteSessions` removes clips only after.
- Every port with state has a contract (`PortContracts`) that the adapter and its fake both pass.

## Consequences

**Better:** scores agree across screens after any formula or config change; opening a night can't fail on a write; a broken store can't swallow nights; a day is deleted or it isn't.

**Limits, honestly:**
- The refresh loads each stale night's events once (a few hundred milliseconds for a year of nights, off the first frame).
- The single-writer rule is a convention the store's doc states, not something the compiler checks.
- The store-unavailable screen has no way out but an update (when the brand has an App Store page); a store that is merely locked would recover at the next launch.

## Alternatives

- **Recompute scores on every read:** loads every night's events for a list.
- **Observe `ModelContext.didSave`:** code for a writer that doesn't exist, and awkward under Swift 6 (contexts aren't `Sendable`).
- **Delete the unreadable store and start empty (SleepGuard's old Release behaviour):** silent data loss.
