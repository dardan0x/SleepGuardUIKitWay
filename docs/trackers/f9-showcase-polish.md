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
| F9-T2 | `docs/ADDING_A_BRAND.md`: add a fourth brand as a worked example, with the diff | Docs | Done | F1 | The diff touches only the brand folder, the brand list and the bootstrap test |
| F9-T3 | Comparison with SleepGuard: same feature in both architectures, what each costs and buys | Docs | Done | F3 | Honest about where the SwiftUI app is simpler |
| F9-T4 | README: screenshots of the three brands, how to run, where to look first | Docs | In Progress | F7 | — |

## F9-T1 — Architecture doc (done 2026-11-17)

- [x] `docs/ARCHITECTURE.md`: the module graph (Tuist's app-level graph plus the package graph from the manifests: `tuist graph` stops at the apps' direct links), each layer with its size and its limits, one screen end to end, brands, the shared repo, the recording pipeline, the rules and what enforces each, the test lanes, the ADRs, where to look first
- [x] Every count and name checked against the source; `docs/architecture/overview.md`'s "SleepDomain depends on nothing" corrected (it depends on SleepCore); `INDEX.md` points to the new doc (both local: `docs/architecture/` is git-ignored)

## F9-T2 — Adding a brand (done 2026-11-17)

- [x] Dawn, a fourth brand: warm sunrise theme and icon, Apple Health, no Snore Interrupter, no Learn tab (a capability mix no other brand has)
- [x] Its diff is the brand folder and one brand-list entry; nothing in the packages, flows, scripts or tests changed. The acceptance named the bootstrap test too: it needed no edit, since it runs inside every brand's app
- [x] Before it, so a brand needs nothing else: `run-tests.sh` and CI find brands by `Apps/<Name>/Sources/Brand.swift` instead of a hard-coded list
- [x] `docs/ADDING_A_BRAND.md` with the real diff; `ARCHITECTURE.md`, `AGENTS.md` / `CLAUDE.md` say four brands
- [x] All four brands' in-app tests pass (9 each)

## F9-T3 — Comparison (done 2026-11-17)

- [x] `docs/COMPARISON.md`: a night's detail in both apps, concern by concern (opening, loading, Health stages, saving, layout, chrome, sheets, delete, brand differences), with sizes and tests measured in both repos
- [x] What the UIKit shape buys and costs, where SleepGuard's is simply better (small features, one team, reading the code), and where SleepGuard pays later
- [x] Found on the way: SleepGuard deletes a night without asking; this app confirms. Left as a difference, noted in the doc

## F9-T4 — README (in progress)

- [x] README rewritten: what the app is, the four brands and their capabilities, how to run, where to look first, why a UIKit shell, layout, status
- [ ] Screenshots of the brands: deferred by the owner until the UI polish is done (a capture script exists: build each brand in Debug, skip onboarding and the briefing through UserDefaults, wait about 45 s for the sample nights, screenshot)

