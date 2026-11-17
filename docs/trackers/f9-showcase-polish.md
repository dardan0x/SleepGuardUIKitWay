# F9 — Showcase polish

> Updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P2 |
| **Milestone** | M4 |
| **Blocked By** | F3 at minimum; best after F7 |
| **Started** | 2026-11-17 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

Someone who opens the repo for ten minutes understands the architecture, why each choice was made, and can see it hold under a change.

## Tasks

| ID | Task | Type | Status | Depends On | Acceptance (short) |
|----|------|------|--------|------------|--------------------|
| F9-T1 | `docs/ARCHITECTURE.md`: verified against the code, with the module graph from `tuist graph` | Docs | Done | F3 | Every claim checked against source |
| F9-T2 | `docs/ADDING_A_BRAND.md`: add a fourth brand as a worked example, with the diff | Docs | Backlog | F1 | The diff touches only the brand folder, the brand list and the bootstrap test |
| F9-T3 | Comparison with SleepGuard: same feature in both architectures, what each costs and buys | Docs | Backlog | F3 | Honest about where the SwiftUI app is simpler |
| F9-T4 | README: screenshots of the three brands, how to run, where to look first | Docs | Backlog | F7 | — |

## F9-T1 — Architecture doc (done 2026-11-17)

- [x] `docs/ARCHITECTURE.md`: the module graph (Tuist's app-level graph plus the package graph from the manifests: `tuist graph` stops at the apps' direct links), each layer with its size and its limits, one screen end to end, brands, the shared repo, the recording pipeline, the rules and what enforces each, the test lanes, the ADRs, where to look first
- [x] Every count and name checked against the source; `docs/architecture/overview.md`'s "SleepDomain depends on nothing" corrected (it depends on SleepCore); `INDEX.md` points to the new doc (both local: `docs/architecture/` is git-ignored)
