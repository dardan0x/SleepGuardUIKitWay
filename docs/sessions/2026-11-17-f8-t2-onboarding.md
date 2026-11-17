
### Completed
- F8-T2: Onboarding on first launch, built content-first.

### Technical Details
- **Shared (0.25.0)**: SleepCore `OnboardingPage` and `OnboardingPages(hasHealth:)` (which pages, Next, Skip to the last page, Back); content kit `OnboardingContent` with SleepGuard's six pages (welcome, features, privacy, Apple Health, microphone, start), permission states as values (`OnboardingPermission`).
- **Preferences**: `hasCompletedOnboarding`, SleepGuard's key.
- **`OnboardingFeature`** (new module): `OnboardingScreen` hosts the content. It asks for the microphone and, when the brand has Health, for Apple Health. "Granted" shows for 0.8 s before the next page; denied moves on at once, as in SleepGuard.
- **`OnboardingFlow`**: finishing saves `hasCompletedOnboarding` and, when Health was allowed here, `syncToHealth` (SleepGuard's rule; first launch means nothing was chosen yet). It then hands back whether the person chose "Start recording".
- **`AppCoordinator`**:
  - Until the preferences are read, the window shows the theme's background, then the onboarding or the tabs.
  - After onboarding, the tabs replace it, and "Start recording" opens a night over them.
  - The unfinished-night offer and the Debug sample nights wait for the tabs.
- Lite has no Health page (no Health port).

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Core/Sources/SleepDomain/Settings/AppPreferences.swift`, `Packages/Adapters/Sources/SleepPersistence/Store/UserDefaultsPreferencesStore.swift`, `Tests/SleepPersistenceTests/SettingsStoresTests.swift` | The flag and its round trip |
| `Packages/Features/Sources/OnboardingFeature/OnboardingScreen.swift`, `Tests/OnboardingFeatureTests/OnboardingScreenTests.swift`, `Package.swift` | New module |
| `Packages/AppShell/Sources/AppShell/{Onboarding/OnboardingFlow,Coordinators/AppCoordinator}.swift`, `Package.swift` | Flow and launch |
| `Packages/AppShell/Tests/AppShellTests/{OnboardingFlowTests,RecordingFlowTests}.swift` | Flow and first-launch tests; launch-recovery tests start onboarded |
| `Packages/Core/Tests/SleepDomainTests/RecordingSessionTests.swift` | The F8-T4 snapshot test waits for the stream (it could read too early) |
| `Apps/HostedTests/{HostedApp,BrandBootstrapTests,StatisticsTabInAppTests,SessionsTabInAppTests,PlayerInAppTests,RecordingInAppTests}.swift` | A fresh install opens on the onboarding: `HostedApp.tabBar()` finishes it ("Just browsing") and waits for the tabs; the bootstrap test also resolves the melody factories |
| `scripts/check-layering.py` | `OnboardingFeature` |
| `docs/architecture/navigation.md`, trackers, Roadmap | Docs |

### Build Status
- All lanes green on the local shared checkout: Core 60, Adapters 18, Presentation 13, Features 22 (Onboarding 2, Recording 4, Session detail 16; the lane prints only the first bundle), AppShell 66, hosted tests in all three brands (9 each); layering, view-size and hardcoded-string checks pass. Re-run on the 0.25.0 release (`TUIST_SHARED_RELEASE=1`): all green.
- Swift couldn't type-check an optional map returning an async closure in `OnboardingFlow`; written as an `if let`.
- `AppCoordinator` resolves its launch services when made: after the preferences' `await`, a parallel test could re-register the shared singleton checkpoint store.

### Next Session
- By hand: the real permission prompts on a fresh install. Then F8-T5, the Learn tab.

### Open Questions
- None.
