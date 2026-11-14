# F6 — Design kit adoption in SleepGuard

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P2 |
| **Milestone** | M2 |
| **Blocked By** | F4 (the kit's API should be settled by two slices first) |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The original SwiftUI app draws its tokens and primitive components from the shared `SleepGuardDesignKit`, so a visual change is made once. This work happens in the SleepGuard repo and is tracked there too.

## Tasks

| ID | Task | Type | Status | Depends On | Where | Acceptance (short) |
|----|------|------|--------|------------|-------|--------------------|
| F6-T1 | SleepGuard's `Theme` is built from the kit's default palette and injected into the environment at the root | Refactor | Backlog | F4 | SleepGuard | Its `@Injected(\.theme)` call sites are untouched; no visual change |
| F6-T2 | Replace SleepGuard's primitive components with the kit's; adapt the domain-typed ones through view-data | Refactor | Backlog | F6-T1 | SleepGuard | Checked against `designs/SleepGuard.pen`; all its tests pass |
| F6-T3 | ADR in SleepGuard; its `AGENTS.md` design section updated | Docs | Backlog | F6-T2 | SleepGuard | — |

## Notes

- If the kit starts fighting SleepGuard's design rules, stop and fork instead; record why.
