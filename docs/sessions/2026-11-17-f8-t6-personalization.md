
### Completed
- F8-T6: Personalization, which finishes F8. It covers the morning briefing with its survey, the profile prompt on the dashboard, and the night's PDF report and clip sharing.

### Technical Details
- **Shared (0.27.0)**:
  - SleepCore `BriefingEngine` returns values, not text, which is this task's acceptance. Its six content modes are picked by the latest night's day, so the same night always gives the same briefing (decided with the user).
  - `BriefingSchedule`, `ProfilePrompt`, `LifestyleLog` / `LifestyleChip`, and `NightReport` with pages.
  - Content kit `BriefingContent` (the values mapped to SleepGuard's strings), `ProfilePromptCard`, and `NightReportPDF`, which draws the report in SwiftUI into a US Letter PDF with every label localized.
- **Core**:
  - `MorningBriefing` decides when the briefing is due, marks it shown, and stores answers.
  - `ProfilePromptCheck` decides whether to show the prompt and counts dismissals.
  - New port `LifestyleLogStore`.
  - Preferences `lastBriefingShown` and `profilePromptDismissCount`, under SleepGuard's keys.
- **Adapters**: `FileLifestyleLogStore` (`LifestyleLogs.json`).
- **Features**:
  - `BriefingFeature` (`BriefingScreen`).
  - The dashboard shows `ProfilePromptCard` when the check says so, with routes to open the profile and to dismiss.
  - The night detail adds a share route for a row; `NightReportExport` writes the PDF (the shell doesn't import the content kit).
- **AppShell**:
  - `AppCoordinator` shows the briefing as a sheet once the tabs are up, after any recovered night, and never over another modal. It counts as shown from when it opens.
  - `StatisticsFlow` opens the profile editor.
  - `NightDetailNavigation` puts a report button in the bar, next to Delete, and sends the report or a clip to `ShareSheet` (`UIActivityViewController`).
- **Not ported**: sharing the whole night's audio. This app keeps the full recording only in Debug.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Core/Sources/SleepDomain/{Ports/LifestyleLogStore,UseCases/MorningBriefing,UseCases/ProfilePromptCheck,Settings/AppPreferences}.swift` | Ports, use cases, preferences |
| `Packages/Core/Sources/SleepDomainTestSupport/FakeSettingsPorts.swift`, `Tests/SleepDomainTests/MorningBriefingTests.swift` | Fake; briefing and prompt tests |
| `Packages/Adapters/Sources/SleepPersistence/{Store/FileLifestyleLogStore,Store/UserDefaultsPreferencesStore,SleepPersistence}.swift`, tests | Store and keys |
| `Packages/Features/Sources/{BriefingFeature/BriefingScreen,StatisticsFeature/StatisticsScreen,SessionDetailFeature/SessionDetailScreen,SessionDetailFeature/NightReportExport}.swift`, `Package.swift` | Screens |
| `Packages/AppShell/Sources/AppShell/{Coordinators/AppCoordinator,Statistics/*,History/*,Container+AppShell,Storage/StorageLocation}.swift`, `Package.swift` | Wiring |
| `Packages/AppShell/Tests/AppShellTests/{PersonalizationFlowTests,HistoryFlowTests,StatisticsFlowTests}.swift` | New flow tests; the detail now has two bar buttons |
| `Packages/Features/Sources/{StatisticsFeature/StatisticsRoutes,SessionDetailFeature/SessionDetailRoutes}.swift` | Dependencies and routes moved out, keeping the screens under 100 lines |
| `Apps/HostedTests/{HostedApp,SessionsTabInAppTests}.swift` | Close the launch briefing; two bar buttons |
| `scripts/check-layering.py` | `BriefingFeature` |
| `docs/features/f8-remaining-features.md`, trackers, Roadmap | F8 done |

### Build Status
- All lanes green on the local shared checkout: Core 65, Adapters 40 (three bundles), Presentation 13, Features 22, AppShell 70, hosted tests in all three brands (9 each); layering, view-size and hardcoded-string checks pass. Re-run on the 0.27.0 release (`TUIST_SHARED_RELEASE=1`): all green.
- In Debug the sample nights make a briefing due at launch, so `HostedApp.tabBar()` closes it (it shows once) before the in-app tests drive the tabs. One run's `xcodebuild` stalled after its tests had finished (they had failed on the open briefing); it hasn't recurred since.

### Next Session
- F8's device checks (Health, stages, the interrupter, the onboarding prompts, a briefing and a PDF). Then F9, showcase polish.

### Open Questions
- Whether this app should keep a full-night recording outside Debug (and then share it).
