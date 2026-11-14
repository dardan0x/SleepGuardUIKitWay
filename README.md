# SleepGuardUIKitWay

SleepGuard rebuilt as a **UIKit shell hosting SwiftUI screens** on a hexagonal core, shipped as three white-label apps from one codebase. It is the architectural sibling of the SwiftUI app in `../SleepGuard` and shares its pure logic and strings through `../SleepGuardShared`.

**Status:** planning and project docs only. No app code yet. See `docs/FeatureTracker.md`.

## Why a UIKit shell

For a new iOS 17 app, `NavigationStack` is less code. This project uses a UIKit shell on purpose:

- One owner for every transition. Coordinators push, present and dismiss; screens only say what the user asked for.
- Flows such as recording, the end-of-night summary and crash recovery belong to a coordinator, not to whichever tab's view happens to be alive.
- It shows both frameworks working together with clear boundaries.

## Where to read

| Doc | What it is |
|---|---|
| `AGENTS.md` / `CLAUDE.md` | Working rules for AI agents and humans |
| `docs/ARCHITECTURE_PLAN.md` | The approved proposal and roadmap |
| `docs/architecture/INDEX.md` | Architecture notes, one topic per file |
| `docs/adr/` | Decisions and their trade-offs |
| `docs/Roadmap.md`, `docs/FeatureTracker.md` | What is planned and where it stands |

## Layout (target)

```
Apps/          one folder per brand: Brand.swift, assets, entitlements
Packages/      Core, Adapters, Presentation, Features, AppShell (local Swift packages)
Project.swift  Tuist: generates the three app targets from one brand list
../SleepGuardShared   SleepCore, SleepStrings, SleepGuardDesignKit (shared with SleepGuard)
```
