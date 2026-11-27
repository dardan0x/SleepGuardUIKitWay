---
date: 2026-11-27
feature: F13
branch: feature/f13/t24-role-suffixes
title: F13-T24 — Ports, use cases and adapters carry their role in the name
---

### Completed
- F13-T24: every port is `…Port`, every use case `…UseCase`, every adapter in this repo `…Adapter`, in the type and its file (ADR 0014). The rule is in AGENTS/CLAUDE.

### Technical Details
- The adapter modules were renamed next: `SleepPersistenceAdapter`, `SleepAudioAdapter`, `SleepHealthAdapter`, with their factory namespaces, test targets, Tuist linking and `ALLOWED_IMPORTS`. `SleepHealthAccessGranter` was considered and dropped, since the module doesn't grant anything; the owner chose the suffix for all three modules.
- Renamed with a word-boundary script, so `FakeSessionRepository`, `makeHealthAccess()` and `DeleteSessions` vs `DeleteSession` stayed intact.
- One file per port: `SnoreInterrupterPorts.swift` split into three; `PreferencesStorePort.swift` and `HealthKitAccessAdapter.swift` split out.
- The audio adapters are the shared `SleepAudioKit` types (also SleepGuard's), so they keep their names; `KitConformances.swift` is the adapter here.
- Asked whether `makeHealthAccess()` could move into the container: it's already registered from `BrandConfiguration.health`. Building it there would make AppShell link `SleepHealth` (and Lite HealthKit), and adapters can't import Factory.

- Option A (public adapters built in the container, no factory enums) was tried and reverted at the owner's request; the factories stay. `HealthAccessPort` stays `nil` for Lite rather than a no-op, because onboarding, Settings and saving read whether it's there; `NoSleepStages` stays the null object where absence doesn't show.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Core/Sources/SleepDomain/Ports/*Port.swift` | 15 ports renamed; the melody ports one per file; `PreferencesStorePort` split out |
| `Packages/Core/Sources/SleepDomain/UseCases/*UseCase.swift` | 12 use cases renamed |
| `Packages/Adapters/Sources/**/*Adapter.swift` | 8 adapters renamed; `HealthKitAccessAdapter` split out of `SleepHealth.swift` |
| `Packages/Adapters/Sources/*Adapter/`, `Tests/*AdapterTests/`, `Package.swift` | Adapter modules renamed |
| `Tuist/ProjectDescriptionHelpers/*`, `scripts/check-layering.py`, `Apps/*/Sources/Brand.swift` | New module names |
| `Packages/*/Tests/**` | Six test files and suites renamed; references updated |
| Features, AppShell, Apps | References updated |
| `AGENTS.md`, `CLAUDE.md` | Naming rule for ports, use cases, adapters |
| `README.md`, `docs/ARCHITECTURE.md`, `docs/COMPARISON.md`, `docs/architecture/*` | New names; diagram realigned; ADR 0014 listed |
| `docs/adr/0014-role-suffixes.md` | New ADR |
| `docs/FeatureTracker.md`, `docs/trackers/f13-architecture-review.md` | F13-T24 |

### Verification
- Four brand schemes build; all test lanes pass; layering, view-size and string checks pass.
- `swiftformat --lint`: one `modifierOrder` error in `SnoreInterrupter.swift:11`, which was already there before this change.
