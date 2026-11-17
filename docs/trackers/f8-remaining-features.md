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
| F8-T2 | Onboarding flow | UI / Shell | Done | F1 | All | `OnboardingFlow`; shown once |
| F8-T3 | Sleep stages from HealthKit | Adapter / UI | Done | F3 | SleepGuard, Nocturne | Lite does not link `SleepHealth`; stage UI absent there |
| F8-T4 | Snore Interrupter: melody playback, custom melody recording; prestart row, bedside overlay, melody gaps in detection | Adapter / UI | Done | F7 | SleepGuard, Nocturne | Capability off in Lite |
| F8-T5 | Learn tab | UI / Shell | Done | F1 | SleepGuard, Nocturne | Tab absent in Lite |
| F8-T6 | Personalization: profile, morning briefing; share and PDF export | UI / Domain | Backlog | F4 | All | Briefing engine returns values; the view maps them to strings |

## F8-T1 — Settings (done 2026-11-17, one branch at the owner's choice)

- [x] Shared (0.22.0): `StoragePlan`, `RecordingDelay`, `RawLog` (moved from SleepGuard), `SleepProfile`; Settings, profile editor, delay row and countdown content; `FlowLayout`; the delay notification string
- [x] SleepGuard hosts the same content (its F26)
- [x] Ports: `PreferencesStore`, `ProfileStore`, `HealthAccess`, `RawLogWriter`; repository and file-store queries for the limits; capture warm-up and raw audio
- [x] Use cases: `EnforceStorageLimits` (also removes files no night or checkpoint refers to), `DeleteAllData`; `CommitSession` writes to Apple Health when on
- [x] `SettingsFeature` (Settings, profile editor), `SettingsFlow`; start delay in `RecordingFlow`; limits at launch and after each save
- [x] Brand capabilities as ports or values (ADR 0006): Health in SleepGuard and Nocturne, none in Lite; no Watch section; rating once a brand has an App Store id
- [ ] On a device: Health permission and writing, the delay with the screen locked, a raw recording

## F8-T3 — Sleep stages (done 2026-11-17)

- [x] Shared (0.23.0): SleepCore `SleepStageBreakdown` (durations, percents, per-stage status from `SleepScoreConfig`, the score's penalty); design kit `SleepStageHypnogram`, `SleepStageLegend`; content kit `SleepStagesCard`, `SleepStagesInfoContent`
- [x] SleepGuard hosts the same content (its F26-T2); its own stage views are gone
- [x] `HealthAccess` refines `SleepStagePort`; `HealthKitAccess.stages(from:to:)` reads Health's staged sleep samples in the night's window
- [x] Stages are read whenever the brand has Health (decided with the user): Health's permission is the gate, no new setting. Lite keeps `NoSleepStages`
- [x] Night detail shows the card when the night has stages; the dashboard shows the latest night's; the info sheet is a route on both, presented by the History and Statistics flows
- [ ] On a device: real stages from an Apple Watch night

## F8-T4 — Snore Interrupter (done 2026-11-17, one task at the owner's choice)

- [x] Shared (0.24.0): SleepCore `SnoreInterrupterMode`, the melody catalog and `CustomMelodies` rules, gap helpers; `SleepMelodies` (the 11 sound files, moved from SleepGuard); melody names and the "My Sound N" name as strings; design kit rows and bedside pieces; content kit `PrestartOptions`, `SnoreInterrupterSettingsContent`, `MelodyPickerContent`, `RecordMelodyContent`
- [x] SleepGuard hosts the same content (its F26-T3)
- [x] Ports `MelodyPlayer`, `MelodyStore`, `MelodyRecorder`; `AudioCapturePort.pause()` / `resume()`
- [x] `SnoreInterrupter` (Core): plays on `.melodyRequested` with the microphone paused; every way it stops resumes the microphone and records the gap. `RecordingSession` performs the melody outputs; SleepGuard's three melody characterization cases pass with the same numbers
- [x] Adapters: `AVMelodyPlayer` (haptic nudge from the shell), `FileMelodyStore` (recordings in `Melodies/`, a JSON list), `AVMelodyRecorder` (10 s cap)
- [x] Prestart row and settings sheet, picker with preview, recorder, bedside note and overlay; `BrandConfiguration.snoreInterrupter` (off in Lite)
- [ ] On a device: a melody over a sleeping phone, the microphone back after it, a recording made and played

## F8-T2 — Onboarding (done 2026-11-17)

- [x] Shared (0.25.0): SleepCore `OnboardingPages` (which pages, Next, Skip to the last, Back); content kit `OnboardingContent` with SleepGuard's six pages
- [x] SleepGuard hosts the same content (its F26-T4); its Health page now follows the `healthSync` flag
- [x] `OnboardingFeature` (`OnboardingScreen`): microphone and, in a Health brand, Apple Health; "granted" shows 0.8 s before the next page
- [x] `OnboardingFlow`: finishing keeps `hasCompletedOnboarding` (SleepGuard's key) and turns on Health sync when allowed here; "Start recording" opens a night over the tabs
- [x] `AppCoordinator`: the theme's background until the preferences are read, then the onboarding or the tabs; the unfinished-night offer and Debug sample nights wait for the tabs
- [ ] By hand: the real microphone and Health prompts on a fresh install

## F8-T5 — Learn tab (done 2026-11-17)

- [x] Shared (0.26.0): content kit `LearnContent` (title row, the page in a web view, or "No content available"); the page loads when its URL changes, not on every update (a SleepGuard flaw); `data-open-external` links open through `openURL`
- [x] SleepGuard hosts the same content (its F26-T5) and its tab order no longer shows Learn when `feature_learn` is off, or twice when it's on
- [x] `LearnFeature` (`LearnScreen`), `LearnFlow`; `BrandConfiguration.learnURL` (decided with the user: a brand value, as there's no Remote Config here). SleepGuard and Nocturne pass `nil` until a page exists; Lite has no tab
- [x] The F1 placeholder flow and screen are gone (nothing else used them)
- [ ] With a real URL: the page loads, an external link opens in Safari

## Notes

- From F7 (2026-11-16, decided with the user): start delay with its countdown screen and warm-up engine, sensitivity setting UI, storage limits, raw sample log go into F8-T1 / F8-T4.
- **Content-first (ADR 0005, F10).** For each screen: SleepGuard's layout moves to the shared `SleepGuardContentKit`, SleepGuard hosts it, and this app adds only the screen (dependencies, routes) and its flow. SleepGuard's sleep-stage views moved to the design kit and content kit with F8-T3.
- Fix, don't port (F8-T3): SleepGuard's score-impact section hard-coded the score's stage constants; the shared content reads `SleepScoreConfig`, so remote config reaches it. Open: the light recommendation text says 45–55% while the status band is 40–60% (both inherited from SleepGuard), and the recommendation texts are fixed, so they'd drift if remote config moved the targets.
- Fix, don't port: SleepGuard maps survey chips by comparing localized strings. Use identifiers.
