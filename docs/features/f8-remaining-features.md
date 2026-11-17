# F8 — Remaining features

The rest of SleepGuard's product, built content-first: each screen's layout lives in the shared `SleepGuardContentKit`, both apps host it, and this app adds the screen, its flow and its ports. Three parts are brand-gated (ADR 0006): Apple Health (and with it sleep stages), the Snore Interrupter, and the Learn tab.

## Files

| File | Purpose |
|------|---------|
| `../SleepGuardShared/Sources/SleepCore/{Storage,Recording,Profile}/*` | Storage plan, start delay, raw log, profile (0.22.0) |
| `../SleepGuardShared/Sources/SleepCore/Night/SleepStageBreakdown.swift` | Stage durations, statuses and penalty (0.23.0) |
| `../SleepGuardShared/Sources/SleepCore/Interrupter/*`, `../SleepGuardShared/Sources/SleepMelodies/*` | Interrupter mode, melody catalog, recording rules; the sounds (0.24.0) |
| `../SleepGuardShared/Sources/SleepCore/Onboarding/OnboardingPages.swift` | Onboarding pages and moves (0.25.0) |
| `../SleepGuardShared/Sources/SleepCore/{Briefing,Report}/*` | Morning briefing as values, its schedule, the profile prompt rule, a night's report (0.27.0) |
| `../SleepGuardShared/Sources/SleepGuardContentKit/{Settings,Profile,Stages,Interrupter,Onboarding,Learn,Briefing,Report}/*` | The screens' content; `NightReportPDF` |
| `Packages/Core/Sources/SleepDomain/Ports/{PreferencesStore,ProfileStore,HealthAccess,RawLogWriter,SnoreInterrupterPorts,LifestyleLogStore}.swift` | Ports |
| `Packages/Core/Sources/SleepDomain/UseCases/{EnforceStorageLimits,DeleteAllData,MorningBriefing,ProfilePromptCheck}.swift` | Use cases |
| `Packages/Core/Sources/SleepDomain/Recording/SnoreInterrupter.swift` | The night's interrupter (microphone paused while it plays) |
| `Packages/Adapters/Sources/SleepPersistence/Store/*` | Preferences, profile, raw log, survey answers |
| `Packages/Adapters/Sources/SleepAudio/Interrupter/*` | Melody player, store, recorder |
| `Packages/Adapters/Sources/SleepHealth/SleepHealth.swift` | Health writes and sleep stages |
| `Packages/Features/Sources/{SettingsFeature,OnboardingFeature,LearnFeature,BriefingFeature}/*` | New screens |
| `Packages/Features/Sources/{RecordingFeature,SessionDetailFeature,StatisticsFeature}/*` | Interrupter screens, stages card, share, profile prompt |
| `Packages/AppShell/Sources/AppShell/{Settings,Onboarding,Learn}/*` | Their flows |
| `Packages/AppShell/Sources/AppShell/Coordinators/AppCoordinator.swift` | Onboarding or tabs at launch; the briefing after the tabs |
| `Packages/AppShell/Sources/AppShell/Brand/BrandComposition.swift`, `Apps/*/Sources/Brand.swift` | `health`, `appStoreID`, `snoreInterrupter`, `learnURL` |

## Routes

| From | Route | To | How |
|------|-------|----|-----|
| Launch, first time | — | Onboarding | Window root; the tabs replace it when done |
| Onboarding | Start recording | Prestart | Over the tabs |
| Launch, new night | — | Morning briefing | Sheet over the tabs, after a recovered night |
| Settings | Profile | Profile editor | Sheet |
| Statistics | Profile prompt, Set Up | Profile editor | Sheet |
| Prestart | Snore Interrupter row | Settings → picker → recorder | Stacked sheets |
| Night detail / dashboard | Stages info | Stages sheet | Sheet |
| Night detail | Report button, row Share | Share sheet | Sheet (`UIActivityViewController`) |

## State

| State | Where | Scope |
|-------|-------|-------|
| `AppPreferences` (settings, interrupter, onboarding, briefing shown, prompt dismissals) | UserDefaults, SleepGuard's keys | App |
| Profile | `Profile.json` | App |
| Survey answers | `LifestyleLogs.json` | App |
| Custom melodies | `Melodies/` with `melodies.json` | App |
| Brand capabilities | `BrandConfiguration` | Build |

## Edge cases

- A brand without Health: no Health rows, no stages, no Health onboarding page.
- Lite: no Snore Interrupter, no Learn tab.
- The briefing: once per new night, never over another modal, off with its setting; counted as shown when it opens.
- The profile prompt's chance is drawn once per appearance.
- A report with many events continues on more pages; an event clip shares only when its file is there.

## Tasks completed

F8-T1 (Settings), F8-T3 (sleep stages), F8-T4 (Snore Interrupter), F8-T2 (onboarding), F8-T5 (Learn), F8-T6 (personalization).
