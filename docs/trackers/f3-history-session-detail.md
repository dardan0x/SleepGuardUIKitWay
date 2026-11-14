# F3 — History → Session Detail

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P0 |
| **Milestone** | M2 |
| **Blocked By** | F2 |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The user sees their nights grouped by month, opens one, reads its score, timeline and events, and can delete it. This is the reference slice: the first complete path from entity to screen, and the example every later feature copies.

## Tasks

| ID | Task | Type | Status | Depends On | Module | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F3-T1 | `HistoryFeature`: screen, state views, month grouping, swipe to delete | UI | Backlog | F2 | HistoryFeature | Live updates from `observeSummaries()`; no refetch on pop |
| F3-T2 | `SessionDetailFeature`: header, timeline, stats grid, event list with category filter | UI | Backlog | F2 | SessionDetailFeature | Matches the design; loads through `LoadSessionDetail` |
| F3-T3 | Composers and `HistoryFlow`: push detail, delete then pop | Shell | Backlog | F3-T1, F3-T2 | AppShell | Flow tests with `NavigatorSpy` |
| F3-T4 | Events sheet as a UIKit sheet presented by the flow | Shell | Backlog | F3-T3 | AppShell, SessionDetailFeature | Detents work; dismissal returns to detail |
| F3-T5 | Timeline, stats grid and legend in the design kit, fed by view-data structs | UI | Backlog | F1-T4 | Shared repo | No domain types in the kit |

## Notes

- Port SleepGuard's `SessionGrouper` logic as a policy.
- Share and PDF export are not in this slice (F8).
