# F6 — Design kit adoption in SleepGuard

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P2 |
| **Milestone** | M2 |
| **Blocked By** | F3-T5 (detail components in the kit). Done when there's time; no longer waits for F4 |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The original SwiftUI app draws its tokens and primitive components from the shared `SleepGuardDesignKit`, so a visual change is made once. This work happens in the SleepGuard repo and is tracked there as **F24 — Shared Design Kit Adoption** (`docs/trackers/f24-shared-design-kit-adoption.md`), with the detailed task list.

**Rule:** a view that only takes values and draws them belongs in the shared kit. A view that loads data, holds state or navigates stays in its app.

## Tasks

| ID | Task | Type | Status | Depends On | Where | Acceptance (short) |
|----|------|------|--------|------------|-------|--------------------|
| F6-T1 | SleepGuard's `Theme` is built from the kit's default palette and injected into the environment at the root | Refactor | Backlog | — | SleepGuard | Its `@Injected(\.theme)` call sites are untouched; no visual change |
| F6-T2 | Replace SleepGuard's primitive components with the kit's (`StatCard`, gauge, charts, buttons, sheet header) | Refactor | Backlog | F6-T1 | SleepGuard | Checked against `designs/SleepGuard.pen`; all its tests pass |
| F6-T2b | Replace SleepGuard's detail components with the kit's view-data versions (`SessionStatsGrid`, `EventRow`, score badge, legends, timeline) | Refactor | Backlog | F6-T2, F3-T5 | SleepGuard | `@Model` values mapped to view data at the call site |
| F6-T3 | ADR in SleepGuard; its `AGENTS.md` design section updated | Docs | Backlog | F6-T2 | SleepGuard | — |

## Notes

- If the kit starts fighting SleepGuard's design rules, stop and fork instead; record why.
