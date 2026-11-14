# F0 — Shared repo

> Updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P0 |
| **Milestone** | M0 |
| **Blocked By** | F0-T3 needs the GitHub CLI or a repo created by hand |
| **Started** | 2026-11-14 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

Code that both apps need lives once, in `../SleepGuardShared`, and both apps consume it. Editing a shared file changes both apps.

## Tasks

| ID | Task | Type | Status | Depends On | Where | Started | Completed |
|----|------|------|--------|------------|-------|---------|-----------|
| F0-T1 | Create the package; move `SleepCore` and `SleepStrings` out of SleepGuard | Refactor | Done | — | Shared, SleepGuard | 2026-11-14 | 2026-11-14 |
| F0-T2 | Prove stored data still opens after the move | Test | Done | F0-T1 | SleepGuard | 2026-11-14 | 2026-11-14 |
| F0-T3 | Private remote for `SleepGuardShared`; push | Infra | Blocked | F0-T1 | Shared | 2026-11-14 | — |
| F0-T4 | Versioned URL dependency in both apps, sibling checkout as local override, `bump-shared.sh` | Infra | Backlog | F0-T3 | Both apps | — | — |
| F0-T5 | Shared-repo CI (tests, strings in sync, builds both apps); SleepGuard CI fetches the shared repo | CI | Backlog | F0-T3 | Shared, SleepGuard | — | — |

## Task Details

### F0-T1 — Create the package and move the code

**Acceptance Criteria:**
- [x] `SleepCore`: score, detection state machine and actor, stored value types, their tests and replay goldens
- [x] `SleepStrings`: catalog, generated `Strings`, generators
- [x] SleepGuard depends on the package and builds (app + widgets)
- [x] All SleepGuard package tests pass; replay goldens unchanged
- [x] ADR in SleepGuard (`docs/adr/0004-shared-repo.md`)

**Notes:**
- SleepGuard's `DesignSystem` re-exports `SleepStrings` (`@_exported import`). A typealias failed in its app and widget targets (member import visibility). Explicit imports everywhere were tried and reverted at the owner's request.
- Left in SleepGuard because each needs a refactor to become pure: episode merging, snoring duration, classifier rules, sensitivity thresholds. Move them when this app needs them (F2, F7).
- Not verified on a simulator holding real pre-move data; only the fixture test.

### F0-T2 — Stored data still opens

**Acceptance Criteria:**
- [x] A store written before the move is checked in as a fixture
- [x] A test opens it and decodes gaps, stage segments, bursts and both enums, with the same score

### F0-T3 — Remote

**Acceptance Criteria:**
- [ ] Private GitHub repo exists
- [ ] `main` pushed

**Notes:** approved by the owner on 2026-11-14. Blocked: `gh` is not installed.

### F0-T4 — Versioned dependency

**Acceptance Criteria:**
- [ ] Both apps declare the package by URL and version
- [ ] A sibling checkout overrides it locally in both apps
- [ ] `scripts/bump-shared.sh` updates the pin
- [ ] Sharing check: edit one string and one score constant locally; both apps pick it up

### F0-T5 — CI

**Acceptance Criteria:**
- [ ] Shared repo: both test lanes, `Strings.swift` in sync with the catalog
- [ ] Shared repo: builds both apps against the candidate commit
- [ ] SleepGuard `tests.yml` fetches the shared repo; its `strings-sync` job is removed
