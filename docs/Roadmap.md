# SleepGuardUIKitWay Roadmap

Vertical slices: the architecture and all three brands first, then one complete feature at a time. Each milestone is demoable. Full reasoning: `ARCHITECTURE_PLAN.md`. Live status: `FeatureTracker.md`.

## M0 — Shared foundation

| # | Feature | Status | Tasks | Notes |
|---|---------|--------|-------|-------|
| F0 | Shared repo | In Progress | 6/6 | Extracted (0.1.0); versioned with a dev-workspace override; CI; design kit (0.2.0); night entities and rules shared by both apps (F0-T6, 0.4.0) |

## M1 — Architecture and brands

| # | Feature | Status | Tasks | Notes |
|---|---------|--------|-------|-------|
| F1 | Foundation | Done | 8/8 | Tuist project, package skeletons, design kit, `ScreenKit`, `AppShell`, three brands launching into a themed tab shell, CI |
| F2 | Domain and persistence | Done | 5/5 | Entities, ports, use cases on `SleepCore`; SwiftData behind a `@ModelActor`; sample-night seeder |

## M2 — First slices

| # | Feature | Status | Tasks | Notes |
|---|---------|--------|-------|-------|
| F3 | History → Session Detail | Done | 5/5 | The reference slice: list with live updates, push to detail, delete, events sheet |
| F4 | Statistics | Done | 5/5 | Dashboard, trends, calendar, last 7 nights |
| F5 | Clip playback | In Progress | 2/5 | Playback port, AVAudioEngine adapter, player sheet |
| F6 | Design kit adoption in SleepGuard | Backlog | 0/4 | The original app moves its tokens and presentational components onto the shared kit (SleepGuard F24); when there's time |

## M3 — The hard part

| # | Feature | Status | Tasks | Notes |
|---|---------|--------|-------|-------|
| F7 | Recording and detection | Backlog | 0/6 | Capture adapter, recording actor, `RecordingFlow`, commit, summary, crash recovery |

## M4 — Parity and polish

| # | Feature | Status | Tasks | Notes |
|---|---------|--------|-------|-------|
| F8 | Remaining features | Backlog | 0/6 | Settings, onboarding, sleep stages, Snore Interrupter, Learn, personalization (three of them brand-gated) |
| F9 | Showcase polish | Backlog | 0/4 | Architecture doc with module graph, "adding a brand" walkthrough, comparison with SleepGuard |

## Dependencies between features

```
F0 → F1 → F2 → F3 → F5 → F7 → F8 → F9
               │    └→ F6 (after F3-T5; when there's time)
               └→ F4
```

## Out of scope

Widgets, Apple Watch, Firebase (replaced by a static per-brand configuration adapter), migrating data from SleepGuard's store.

## Known issues

- None yet.
