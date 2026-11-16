# F10 — Shared screen content

> Updated by the AI after every task in this feature. Task details are expanded when the task starts.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P1 |
| **Milestone** | M4 |
| **Blocked By** | F7 |
| **Started** | 2026-11-16 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The loaded layout of each screen exists once, in the shared repo's `SleepGuardContentKit`, and both apps host it. Screens (loading, dependencies, navigation, alerts, the navigation bar) stay in each app. Decided with the owner on 2026-11-16; see ADR 0005. In SleepGuard this is tracked as **F25 — Shared Screen Content**.

**The test:** a view that can be rendered from plain values alone is shared; one that needs a port, a route, an alert or a sheet stays in the app.

## Tasks

Each task from T2 on is one shared release, then SleepGuard adopts it, then this app does, with every lane on the release.

| ID | Task | Type | Status | Depends On | Where | Acceptance (short) |
|----|------|------|--------|------------|-------|--------------------|
| F10-T1 | Decision recorded: ADR here and in SleepGuard, the three-layer rule in both apps' AGENTS/CLAUDE, trackers, layering table | Docs | Done | F7 | Both apps | — |
| F10-T2 | `SleepGuardContentKit` product; Dashboard, Trends, Calendar, Last 7 Nights content; empty and loading placeholders | Shared / Refactor | Done | F10-T1 | Shared, both apps | `StatisticsFeature/Views/*` gone here; SleepGuard's Statistics screens host the same content |
| F10-T3 | Nights list content; `NightsByMonth` rule in `SleepCore` | Shared / Refactor | Backlog | F10-T2 | Shared, both apps | `HistorySections` and SleepGuard's `SessionGrouper` gone; both apps' grouping tests pass on the rule |
| F10-T4 | Night detail content, events sheet content, player card and event list | Shared / Refactor | Backlog | F10-T2 | Shared, both apps | `SessionDetailFeature/Views/*` gone here |
| F10-T5 | Prestart, bedside clock and summary content (slots for SleepGuard's melody rows and overlay) | Shared / Refactor | Backlog | F10-T2 | Shared, both apps | The three recording screens here are containers only |
| F10-T6 | Review: no screen-content view left in either app for the shared screens; docs final; feature doc | Docs | Backlog | F10-T3, T4, T5 | Both apps | — |

## Notes

- SleepGuard's content views read `SleepSession`. Its containers map to `SleepCore` values first (`summaryWithoutEvents`, `nightSummary`, `night`); lists must use the cached summaries (event faulting).
- Deleting SleepGuard files needs the owner's yes each time.
- SleepGuard keeps its `DesignSystem` package as its bridge to the shared kit (`AppTheme`, model adapters, re-exports). Its sleep-stage views move to the kit with F8-T3.
- F8 is built content-first (ADR 0005).

## Task Details

### F10-T2 — Statistics content (done 2026-11-16)
- [x] Shared (0.17.0): product `SleepGuardContentKit` (re-exports the design kit); `StatisticsDashboardContent` (slot for an extra below the stats), `TrendsContent` + `TrendsRange`, `CalendarContent`, `LastSevenNightsContent`, `StatisticsEmptyContent`, `StatisticsLoadingContent`; gallery; render tests in both themes and text tests. `Theme.previewAlternate` made public for previews and tests
- [x] Content takes chosen values, not every night: the screen owns the range, month and selected day, and passes the period, the grid's nights, the day stats. That's what lets SleepGuard keep choosing nights without reading events
- [x] Here: the four screens host the content; `StatisticsFeature/Views/*` (5 files) and the two render-test files deleted (their content is tested in the shared repo); `StatisticsFeatureTests` target removed
- [x] SleepGuard F25-T2: its four screens host the same content (10 files deleted, approved)
- [x] Visible changes, approved: SleepGuard's calendar line is now localized ("62 out of 100"). Here: the empty state's button sits closer to its text (SleepGuard's spacing), the calendar's day title is "Monday, Nov 16" (SleepGuard's format)
- [x] Every lane against the local shared checkout; dashboard screenshot in the app unchanged


### F10-T1 — Decision recorded (done 2026-11-16)
- [x] ADR 0005 here; ADR 0006 in SleepGuard
- [x] AGENTS.md / CLAUDE.md in both apps: the three layers and the test
- [x] `check-layering.py`: features may import `SleepGuardContentKit`
- [x] Trackers: this file, dashboard, roadmap, F8 note; SleepGuard F25
