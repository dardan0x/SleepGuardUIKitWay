
### Completed
- F9-T3: `docs/COMPARISON.md`, one feature in both architectures and what each costs and buys.

### Technical Details
- **The feature**: a night's detail. Both apps draw it with the same shared `NightDetailContent` and compute with the same SleepCore rules, so only the architecture differs.
- **Concern by concern**: opening, loading, Apple Health stages, saving the new score, layout, title and bar, sheets, delete, brand differences. Each row names the file in each repo.
- **Measured in both repos**:
  - about 500 lines in 4 files (SleepGuard) against about 480 lines in 9 files (here);
  - 10 model tests on an in-memory store against 9 use case tests on fakes, 11 navigation tests over a spy, and an in-app test per brand.
- **Honest sections**:
  - what this shape buys (testable navigation, rules on macOS, brand values in one place, storage behind a port, enforced boundaries);
  - what it costs (indirection, per-screen ceremony, workarounds the boundaries force, ports to keep in step, slower suites, the singleton and type-checker snags);
  - where SleepGuard's shape is simply better (small features like Learn, one team, reading the code);
  - where SleepGuard pays later.
- **Found on the way**: SleepGuard deletes a night without asking; this app confirms. Noted, not changed.

### Files Changed
| File | What Changed |
|------|--------------|
| `docs/COMPARISON.md` | New |
| `docs/ARCHITECTURE.md` | Links it |
| `docs/trackers/f9-showcase-polish.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | F9-T3 |

### Build Status
- Docs only.

### Next Session
- F9-T4: the README with the brands' screenshots.

### Open Questions
- Whether SleepGuard should ask before deleting a night, as this app does.
