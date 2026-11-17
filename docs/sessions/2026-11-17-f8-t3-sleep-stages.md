
### Completed
- F8-T3: Sleep stages from Apple Health on the night detail and the dashboard, with the info sheet, built content-first.

### Technical Details
- **Shared (0.23.0)**: SleepCore `SleepStageBreakdown` (per-stage durations and percents, `StageStatus` from `SleepScoreConfig`'s targets with light's 40–60% band, the score's own `stagePenalty`, now public); design kit `SleepStageHypnogram` and `SleepStageLegend`; content kit `SleepStagesCard` (collapse is the card's own state, the info button a closure) and `SleepStagesInfoContent` (your stages, score impact).
- **Reading** (decided with the user): whenever the brand has Health. `HealthAccess` refines `SleepStagePort`; the container registers the brand's Health port, or `NoSleepStages` (Lite). Health's permission (the Sync to Apple Health switch) is the gate; no new setting.
- **HealthKit** (`HealthKitAccess.stages(from:to:)`): staged sleep samples in the night's window, sorted by start; core → light, deep, REM, awake; anything else (our own "asleep" sample, in bed) is dropped. The mapping is a static function, tested without HealthKit.
- **Night detail**: `LoadSessionDetail` already fetched stages for a night without any and saved its new score; the screen now shows the card when the night has stages.
- **Dashboard**: `LatestNightStages` reads the latest night (summaries carry no stages) whenever its summary changes, and fills the content's extra slot. No Health read there, as in SleepGuard: stages arrive when the night is opened.
- **Info sheet**: a route on both screens (`showStagesInfo`), presented by `NightDetailNavigation` (the Statistics flow goes through it) as a large sheet hosting `SleepStagesInfoScreen`.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Core/Sources/SleepDomain/Ports/{HealthAccess,SleepStagePort}.swift`, `SleepDomainTestSupport/FakeSettingsPorts.swift` | Health reads stages; fake gains stages |
| `Packages/Adapters/Sources/SleepHealth/SleepHealth.swift`, `Package.swift`, `Tests/SleepHealthTests/HealthKitStageTests.swift` | HealthKit stage query and mapping; new test target |
| `Packages/Features/Sources/SessionDetailFeature/{SessionDetailScreen,SleepStagesInfoScreen}.swift` | Stages card; info sheet screen; route |
| `Packages/Features/Sources/StatisticsFeature/{StatisticsScreen,LatestNightStages}.swift` | Latest night's stages on the dashboard; route |
| `Packages/AppShell/Sources/AppShell/{Container+AppShell,History/NightDetailNavigation,History/HistoryComposers,Statistics/StatisticsFlow,Storage/NoSleepStages}.swift` | Port per brand; sheet presentation |
| `Packages/AppShell/Tests/AppShellTests/{HistoryFlowTests,StatisticsFlowTests}.swift` | Sheet from both screens; Health brands get stages, Lite none |
| `docs/adr/0006-brand-capabilities.md`, trackers, Roadmap | Docs |

### Build Status
- All lanes green on the local shared checkout: Core 47, Adapters 15 (with the stage mapping), Presentation 13, Features 4, AppShell 54, hosted tests in all three brands (9 each). Re-run on the 0.23.0 release (`TUIST_SHARED_RELEASE=1`): all green.
- Swift couldn't type-check `self.healthAccess() ?? NoSleepStages()` (optional existential against a concrete type); written as a `guard let`.
- Xcode open on the workspace holds package resolution: `tuist generate` waits forever. Close it before `run-tests.sh`.

### Next Session
- Device check: real stages from an Apple Watch night. Then F8-T4, Snore Interrupter.

### Open Questions
- The light recommendation text says 45–55% while the status band is 40–60% (both from SleepGuard). The recommendation texts are fixed, so they'd drift if remote config moved the targets.
