---
date: 2026-11-14
feature: multiple
branch: main
title: Architecture plan approved; shared repo extracted; project docs set up
---

### Completed
- Analysed SleepGuard and wrote the architecture proposal, approved by the owner: `docs/ARCHITECTURE_PLAN.md`.
- F0-T1, F0-T2 (done in the SleepGuard and SleepGuardShared repos): `SleepCore` and `SleepStrings` extracted from SleepGuard into `../SleepGuardShared`; SleepGuard consumes them; a pre-move store fixture proves stored data still opens.
- F1-T1: this repo's docs and agent setup.

### Technical Details
- Decisions taken with the owner: vertical slices first; Tuist; three brands (SleepGuard, SleepGuard Lite, Nocturne); shared code in its own repo.
- In SleepGuard, `DesignSystem` re-exports `SleepStrings`. Explicit imports everywhere were implemented and then reverted at the owner's request. This repo matches that: `SleepGuardDesignKit` will re-export `SleepStrings` (owner's decision).

### Files Changed
| File | What Changed |
|------|--------------|
| `AGENTS.md`, `CLAUDE.md` | Project rules |
| `README.md`, `.gitignore`, `.swiftformat` | Repo basics (`.swiftformat` copied from SleepGuard) |
| `docs/ARCHITECTURE_PLAN.md` | The approved proposal |
| `docs/architecture/*.md` (11 notes) | Overview, modules, domain, composition, navigation, dependencies, brands, concurrency, testing, feature template, review checklist |
| `docs/adr/0001`–`0004` | UIKit shell + SwiftUI screens; hexagonal core; white-label brands; shared repo |
| `docs/Roadmap.md`, `docs/FeatureTracker.md`, `docs/trackers/f0`–`f9` | Roadmap and trackers (10 features, 49 tasks) |
| `docs/CODING_WORKFLOW.md`, `docs/templates/*`, `docs/sessions/README.md` | Process, templates, session convention |
| `scripts/compile-sessions.py` | Session compiler, adapted (no archive) |

### Architecture Decisions
- See ADRs 0001–0004.

### Build Status
- No app code in this repo yet; nothing to build.
- SleepGuard after the extraction: app and widgets build; all 8 package suites pass; layering, view-size, hardcoded-string and format checks pass.
- SleepGuardShared: 30 tests pass on the simulator; `SleepCore` also passes on macOS; replay goldens unchanged.
- Not verified: SleepGuard on a simulator holding real pre-move data.

### Suggested Branch
`main` (initial docs commit)

### Suggested Commit
`F1-T1 — Project docs, architecture notes, ADRs and trackers`

### Next Session
- F0-T3: create the private remote for `SleepGuardShared` (needs `gh` installed, or the repo created by hand).
- F1-T2: Tuist project with three brand targets that launch.

### Open Questions
- Remote for this repo too?
