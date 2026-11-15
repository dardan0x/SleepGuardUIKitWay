
### Completed
- F4 planned in detail: the statistics rules go to the shared repo (decided with the user), so both apps compute every number the same way.
- F4-T1: `SleepCore/Statistics` (shared, for 0.7.0) with 25 tests, 13 of them SleepGuard's cases with the same numbers.
- F4-T2: SleepGuard's Statistics calls the shared rules (SleepGuard branch `feature/shared/f4-t2-shared-statistics`).

### Technical Details
- Rules work on `NightSummary` (no events). New `NightSummary.loudestIntensity` for calendar colours, trend bars, last-7 rows and "loud nights"; `SnoreIntensity` is `Comparable`.
- In SleepGuard, choosing nights never reads events (`summaryWithoutEvents`); full summaries only for the nights shown. Event faulting has crashed there before.
- This branch: the plan and notes, the 0.7.0 bump, and the store's `loudestIntensity` column (the observe test failed on 0.7.0 because the stored summary dropped the new field).

### Build Status
- Shared: SleepCore 97, design kit 6, strings 2 pass.
- SleepGuard against the local shared checkout: 8 suites pass, no existing test changed; app builds; format, layering, view size pass.

- Against shared 0.7.0 (release): this repo's package lanes and in-app tests for all three brands pass; SleepGuard's 8 suites and its project build pass.

### Next Session
- F4-T3: dashboard screen.
