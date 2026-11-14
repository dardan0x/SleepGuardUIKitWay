# F4 — Statistics

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P1 |
| **Milestone** | M2 |
| **Blocked By** | F2 |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The user sees last night's summary and a seven-night chart on the dashboard, and can open trends, a calendar and the last seven nights.

## Tasks

| ID | Task | Type | Status | Depends On | Module | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F4-T1 | `BuildDashboard` policy/use case and week-over-week trend, ported from `DashboardState.make` | Domain | Backlog | F2 | SleepDomain | Same outputs as SleepGuard's Statistics tests |
| F4-T2 | Dashboard screen | UI | Backlog | F4-T1 | StatisticsFeature | `ViewState` with empty state; matches the design |
| F4-T3 | Trends, calendar, last 7 nights screens | UI | Backlog | F4-T1 | StatisticsFeature | Swift Charts; computed values come from policies, not views |
| F4-T4 | Composers and `StatisticsFlow`; "start recording" intent goes to `AppCoordinator` | Shell | Backlog | F4-T2, F4-T3 | AppShell | Flow tests with `NavigatorSpy` |
