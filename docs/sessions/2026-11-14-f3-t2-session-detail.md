
### Completed
- F3-T2: `SessionDetailFeature` — screen (loading / loaded / error with retry, loading through `LoadSessionDetail`), header (gauge, four stats, disturbances), event filter, event rows collapsed per snoring episode, "Show all" route.

### Technical Details
- `EventFilter.available(for:)` and `DetailEventRow.make(...)` are pure and tested; same row rule as SleepGuard (episodes keyed by their representative event).
- Retry: `.task(id:)` keyed on the loading state, so "Try again" re-runs the load.
- `SessionDetail` gained a public initializer.
- Scheme for a two-product package is `Features-Package` (the test script already picks it).

### Build Status
- `Features` package: History 4 + SessionDetail 5 tests pass, standalone. Domain 10 pass. Layering, view size (10 view files), strings, format: pass.
- Not verified: the segmented filter on screen (doesn't render in `ImageRenderer`); comes with F3-T3.

### Next Session
- F3-T3: composers and the History flow.
