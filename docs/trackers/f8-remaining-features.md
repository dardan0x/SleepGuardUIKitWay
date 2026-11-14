# F8 — Remaining features

> Updated by the AI after every task in this feature. Each task becomes its own feature tracker if it turns out larger than a few days.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P2 |
| **Milestone** | M4 |
| **Blocked By** | F7 |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The rest of SleepGuard's product, three parts of it switched per brand.

## Tasks

| ID | Task | Type | Status | Depends On | Brands | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F8-T1 | Settings: permissions, recording options, appearance, storage limits, delete all data | UI / Domain | Backlog | F7 | All | `EnforceStorageLimits` and delete-all are use cases |
| F8-T2 | Onboarding flow | UI / Shell | Backlog | F1 | All | `OnboardingFlow`; shown once |
| F8-T3 | Sleep stages from HealthKit | Adapter / UI | Backlog | F3 | SleepGuard, Nocturne | Lite does not link `SleepHealth`; stage UI absent there |
| F8-T4 | Snore Interrupter: melody playback, custom melody recording | Adapter / UI | Backlog | F7 | SleepGuard, Nocturne | Capability off in Lite |
| F8-T5 | Learn tab | UI / Shell | Backlog | F1 | SleepGuard, Nocturne | Tab absent in Lite |
| F8-T6 | Personalization: profile, morning briefing; share and PDF export | UI / Domain | Backlog | F4 | All | Briefing engine returns values; the view maps them to strings |

## Notes

- Fix, don't port: SleepGuard maps survey chips by comparing localized strings. Use identifiers.
