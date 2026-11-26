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
| F5 | Clip playback | Done | 5/5 | Playback port, AVAudioEngine adapter, player sheet |
| F6 | Design kit adoption in SleepGuard | Done | 4/4 | The original app moves its tokens and presentational components onto the shared kit (SleepGuard F24); when there's time |

## M3 — The hard part

| # | Feature | Status | Tasks | Notes |
|---|---------|--------|-------|-------|
| F7 | Recording and detection | Done (device check open) | 7/7 | Capture adapter, recording actor, `RecordingFlow`, commit, summary, crash recovery |

## M4 — Parity and polish

| # | Feature | Status | Tasks | Notes |
|---|---------|--------|-------|-------|
| F10 | Shared screen content | Done | 7/7 | Each screen's layout once, in the shared `SleepGuardContentKit`; screens stay per app (ADR 0005). Before F8 |
| F8 | Remaining features | Done | 6/6 | Settings, onboarding, sleep stages, Snore Interrupter, Learn, personalization (three of them brand-gated) |
| F11 | UIKit screen containers | Done | 1/1 | Every screen a UIKit controller (ADR 0007): History a collection view, Onboarding a page view controller, Session Detail a compositional layout, the rest hosting their shared content; navigation stays with coordinators. On shared 0.28.0 |
| F12 | View models and factories | Done | 1/1 | A view model for every screen (checked), tested without UIKit; the flows' factories build them (ADR 0008) |
| F13 | Architecture review fixes | Done | 15/15 | The review's verdicts: versioned scores, read-only detail, safe store failures, SleepGuard's 20 Hz detection input with calls as gaps, writes off the sample path, `AppComposition` (no `Container.shared`), navigator races, atomic day delete, deep links, port contracts, compile-time screen bans, cheaper CI (ADRs 0009–0012). On shared 0.31.0 |
| F9 | Showcase polish | In Progress | 3/4 | Architecture doc with module graph, "adding a brand" walkthrough (Dawn, a fourth brand), comparison with SleepGuard, README. The brands' screenshots wait for the UI polish |

## Dependencies between features

```
F0 → F1 → F2 → F3 → F5 → F7 → F10 → F8 → F9
               │    └→ F6 (after F3-T5; when there's time)
               └→ F4

F10 → F11 → F12 → F13 → F9-T4 (screenshots)
```

## Out of scope

Widgets, Apple Watch, Firebase (replaced by a static per-brand configuration adapter), migrating data from SleepGuard's store.

## Still open

- **Screenshots** of the brands in the README (F9-T4), after the UI polish (F11 changed every screen's container).
- **Device checks** (F7, F8): a real night on a phone, Apple Health with a Watch night, the start delay with the screen locked, a Snore Interrupter melody, the onboarding's permission prompts, a briefing and a PDF. Listed in the F7 and F8 trackers.
- **Learn page**: SleepGuard and Nocturne have no `learnURL` yet, so the tab shows "No content available".
- **Dawn**: kept as a fourth brand or only as the example in `docs/ADDING_A_BRAND.md` (it costs a target and a CI build).
- **F0**: the shared repo's CI doesn't build this app yet.
