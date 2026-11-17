# F8 — Remaining features

> Updated by the AI after every task in this feature. Each task becomes its own feature tracker if it turns out larger than a few days.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P2 |
| **Milestone** | M4 |
| **Blocked By** | F7 |
| **Started** | 2026-11-17 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The rest of SleepGuard's product, three parts of it switched per brand.

## Tasks

| ID | Task | Type | Status | Depends On | Brands | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F8-T1 | Settings: permissions, recording options, appearance, storage limits, delete all data | UI / Domain | Done | F7 | All | `EnforceStorageLimits` and delete-all are use cases |
| F8-T2 | Onboarding flow | UI / Shell | Backlog | F1 | All | `OnboardingFlow`; shown once |
| F8-T3 | Sleep stages from HealthKit | Adapter / UI | Backlog | F3 | SleepGuard, Nocturne | Lite does not link `SleepHealth`; stage UI absent there |
| F8-T4 | Snore Interrupter: melody playback, custom melody recording; prestart row, bedside overlay, melody gaps in detection | Adapter / UI | Backlog | F7 | SleepGuard, Nocturne | Capability off in Lite |
| F8-T5 | Learn tab | UI / Shell | Backlog | F1 | SleepGuard, Nocturne | Tab absent in Lite |
| F8-T6 | Personalization: profile, morning briefing; share and PDF export | UI / Domain | Backlog | F4 | All | Briefing engine returns values; the view maps them to strings |

## F8-T1 — Settings (done 2026-11-17, one branch at the owner's choice)

- [x] Shared (0.22.0): `StoragePlan`, `RecordingDelay`, `RawLog` (moved from SleepGuard), `SleepProfile`; Settings, profile editor, delay row and countdown content; `FlowLayout`; the delay notification string
- [x] SleepGuard hosts the same content (its F26)
- [x] Ports: `PreferencesStore`, `ProfileStore`, `HealthAccess`, `RawLogWriter`; repository and file-store queries for the limits; capture warm-up and raw audio
- [x] Use cases: `EnforceStorageLimits` (also removes files no night or checkpoint refers to), `DeleteAllData`; `CommitSession` writes to Apple Health when on
- [x] `SettingsFeature` (Settings, profile editor), `SettingsFlow`; start delay in `RecordingFlow`; limits at launch and after each save
- [x] Brand capabilities as ports or values (ADR 0006): Health in SleepGuard and Nocturne, none in Lite; no Watch section; rating once a brand has an App Store id
- [ ] On a device: Health permission and writing, the delay with the screen locked, a raw recording

## Notes

- From F7 (2026-11-16, decided with the user): start delay with its countdown screen and warm-up engine, sensitivity setting UI, storage limits, raw sample log go into F8-T1 / F8-T4.
- **Content-first (ADR 0005, F10).** For each screen: SleepGuard's layout moves to the shared `SleepGuardContentKit`, SleepGuard hosts it, and this app adds only the screen (dependencies, routes) and its flow. SleepGuard's sleep-stage views move to the design kit with F8-T3.
- Fix, don't port: SleepGuard maps survey chips by comparing localized strings. Use identifiers.
