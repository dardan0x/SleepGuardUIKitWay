# F0 — Shared repo

> Updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress (UIKitWay side of T4/T5 waits for F1) |
| **Priority** | P0 |
| **Milestone** | M0 |
| **Blocked By** | — |
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
| F0-T3 | Remote for `SleepGuardShared`; push | Infra | Done | F0-T1 | Shared | 2026-11-14 | 2026-11-14 |
| F0-T4 | Versioned URL dependency in SleepGuard, dev workspace as local override, `bump-shared.sh` | Infra | Done | F0-T3 | SleepGuard | 2026-11-14 | 2026-11-14 |
| F0-T5 | Shared-repo CI (tests, strings in sync, builds SleepGuard); SleepGuard CI fetches the shared repo | CI | Done | F0-T3 | Shared, SleepGuard | 2026-11-14 | 2026-11-14 |

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
- [x] GitHub repo exists (`dardan0x/SleepGuardShared`)
- [x] `main` pushed; tag `0.1.0` pushed

**Notes:** the owner created the repo and pushed. Made **public** (owner's choice): SleepGuard is public and its CI must fetch the package without a token, and the code was already public in SleepGuard's history.

### F0-T4 — Versioned dependency

**Acceptance Criteria:**
- [x] SleepGuard declares the package by URL, `exact: "0.1.0"` (6 manifests)
- [x] `SleepGuard.xcworkspace` adds `../SleepGuardShared` as a local package and overrides the release
- [x] `scripts/bump-shared.sh <version>` checks the tag, rewrites the manifests, re-resolves both lockfiles
- [x] Sharing check: a deliberate error added to the local shared checkout broke the workspace build and not the project build
- [ ] SleepGuardUIKitWay: same setup once its Tuist project exists (F1-T2/T3)

**Notes:**
- Owner chose versioned URL + workspace over a plain path dependency, knowing that `run-tests.sh`, project and CLI builds use the release until a new version is tagged and bumped.
- The workspace has its own `Package.resolved`; it was seeded from the project's so both pin the same Firebase/Factory versions (a fresh resolve picked newer ones).
- `.xcodebuildmcp/config.yaml` now points at the workspace. Not verified: the build MCP server was not connected this session.

### F0-T5 — CI

**Acceptance Criteria:**
- [x] Shared repo `tests.yml`: SleepCore on macOS, SleepStrings on a simulator, `Strings.swift` in sync
- [x] Shared repo: builds SleepGuard's dev workspace against the candidate commit
- [ ] … and SleepGuardUIKitWay, once it has code
- [x] SleepGuard: packages resolve the public release (no workflow change needed); `strings-sync` removed from `quality.yml`

**Notes:**
- Not run on GitHub yet: nothing has been pushed since the workflow was written.
- The shared CI's SleepGuard job builds SleepGuard `main`, which only has the workspace after the shared-repo branch is merged. Until then it fails on `main`; run it by hand with `sleepguard_ref` set to the feature branch.
