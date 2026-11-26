# F13 — Architecture review fixes

> Updated by the AI after every task in this feature.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P0 (T1–T5) / P1 |
| **Milestone** | M5 |
| **Blocked By** | — |
| **Started** | 2026-11-26 |
| **Completed** | — |
| **Feature Doc** | — |
| **Branch** | `feature/f13-architecture-review` (task branches `feature/f13/t#-slug`, merged by the owner through PRs) |

## Summary

Fixes this app's verdicts from the principal-level architecture review of the three repos, each checked against the code first: stale stored scores after a formula change, a detail load that writes, store observation, a silent in-memory store, detection fed per buffer instead of at SleepGuard's 20 Hz, interruptions not recorded, I/O on the sample path, the global brand key and whole-container flows, navigator races, an oversized recording flow, a non-atomic day delete and static chrome, deep links promised but missing, fakes that can drift from adapters, regex-only bans, and CI cost. SleepGuard and the shared repo were fixed first (SleepGuard F27; shared 0.29.1 and 0.30.0).

### Decisions (owner, 2026-11-26)
- Scope: the review's verdicts plus deep links, the recording-flow split, day delete and dynamic chrome, structural lint with CI and a theme check.
- The 20 Hz decimation lives in `RecordingSession` (the domain owns the rule).
- Git: a feature branch with a PR per task; the owner commits and merges.

## Tasks

| ID | Task | Type | Status | Depends On | Where |
|----|------|------|--------|------------|-------|
| F13-T1 | Adopt shared 0.30.0 and `SaveRules` | Dependency | Done | — | all packages, AppShell |
| F13-T2 | Stored scores carry their version; refresh at launch (Q9) | Bug / Data | Backlog | T1 | SleepDomain, SleepPersistence, AppShell |
| F13-T3 | Detail load is read-only; narrow stage writes (Q34, Q37) | Refactor | Backlog | T2 | SleepDomain, SleepPersistence, SessionDetailFeature |
| F13-T4 | Observation follows the store (Q37) | Bug | Backlog | T3 | SleepPersistence |
| F13-T5 | "We couldn't open your data" + shared 0.31.0 (Q55) | Data safety | Backlog | T4 | shared, AppShell |
| F13-T6 | Same samples as SleepGuard; interruptions; FFT; thermal (Q14, Q17) | Detection | Backlog | T1 | SleepDomain, SleepAudio |
| F13-T7 | Writes leave the sample path (Q13, Q39) | Performance | Backlog | T6 | SleepDomain |
| F13-T8 | Typed composition (Q47, Q48) | Architecture | Backlog | T5 | AppShell, Apps |
| F13-T9 | Navigator races (Q45) | Bug | Backlog | — | ScreenKit, AppShell |
| F13-T10 | Split `RecordingFlow` (Q44) | Refactor | Backlog | T8 | AppShell |
| F13-T11 | Atomic day delete; dynamic chrome (Q38, Q43) | Bug / UI | Backlog | T5 | SleepDomain, SleepPersistence, ScreenKit, features |
| F13-T12 | Deep links (Q28) | Feature | Backlog | T8 | Apps, AppShell |
| F13-T13 | Port contract tests (Q59) | Tests | Backlog | — | SleepDomain, Adapters |
| F13-T14 | Structural lint, theme check, CI (Q63, Q51, Q62) | Tooling | Backlog | — | ScreenKit, scripts, CI |
| F13-T15 | Docs and close-out | Docs | Backlog | all | docs |

## Task Details

### F13-T1 — Adopt shared 0.30.0 and `SaveRules`

| Field | Value |
|-------|-------|
| Status | Done |
| Started | 2026-11-26 |
| Completed | 2026-11-26 |

**Acceptance Criteria:**
- [x] Every manifest and `Project.swift` pin 0.30.0; resolved files follow
- [x] The 0.30.0 compatibility changes: `.interruptionGap` handled in `RecordingSession`; the gap banner shows melody gaps only
- [x] `SaveRules` replaces the deprecated `Night.minimumSaveDuration` everywhere; the composition registers it (Debug 120 s, Release `.standard`)
- [x] All four brands build; all lanes pass on the release (`TUIST_SHARED_RELEASE=1`); checks pass

**Notes:**
- `saveRules` is a container registration (Debug 120 s, Release `.standard`), passed into `CommitSession`, `ShouldAskForProfile`, `SessionSummaryViewModel` and `LiveRecordingModel`; both "too short" alerts read the minutes from it. Nothing references `Night.minimumSaveDuration` any more, so 0.31.0 can remove it.
- Verified on the release (`TUIST_SHARED_RELEASE=1`): all four brands build; Core 65, Adapters 18, Presentation 18, Features 6, AppShell 70, hosted 9 × 4 pass; layering, view size and strings checks pass.
- SwiftFormat 0.55.5 flags three files this task didn't touch (`FileMelodyStoreTests`, `AVMelodyRecorder`, `SnoreInterrupter`), already on `main`; left alone.
- Branch `feature/f13/t1-shared-0-30-save-rules`
