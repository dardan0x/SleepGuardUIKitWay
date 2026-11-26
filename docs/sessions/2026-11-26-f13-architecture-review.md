---
date: 2026-11-26
feature: F13
branch: feature/f13-architecture-review
title: F13 architecture review fixes, T1–T15 (shared 0.30.0 and 0.31.0)
---

### Completed
- F13 (architecture review fixes) planned with the owner: 15 tasks, every review concern checked against this repo's code first. Tracker `docs/trackers/f13-architecture-review.md`.
- F13-T1: shared 0.30.0 pinned, with the compatibility changes it needs, and `SaveRules` in place of the deprecated `Night.minimumSaveDuration`.
- F13-T2: stored summaries carry their score version; stale ones are recomputed at launch.
- F13-T3: the detail load only reads; stages are added by a separate command with a narrow store write.
- F13-T4: store observers get every write; a failed re-read after a commit is logged, not thrown.
- F13-T5: store-unavailable screen on shared 0.31.0 (tagged by the owner).
- F13-T6: detection fed at 20 Hz like SleepGuard; calls become interruption gaps; FFT only with the raw log; thermal logging.
- F13-T7: checkpoint and raw-log writes off the sample path.
- F13-T9: navigator operations run serially; flows dismiss what they presented.
- F13-T13: port contracts run against fakes and adapters; the fake session repository's event order fixed.
- F13-T14: unavailable `present` on screens, themed hosting only through ScreenKit, a leak check, cheaper CI.
- F13-T8: `AppComposition` is the composition root; flows take their dependencies explicitly.
- F13-T10: `RecordingFlow` split into interrupter navigation and the night's device lifecycle.
- F13-T11: atomic day delete; the report button shows its work and failures.
- F13-T12: deep links routed by the app coordinator.
- F13-T20: release C (0.36.0): the repository stores the shared SleepStore records and schema.
- F13-T19: release B (0.35.0): the audio adapters are the shared SleepAudioKit behind the unchanged ports.
- F13-T18: uniform the apps, release A (0.34.0): logging, classifier, sample nights, layout, file stores, storage sweep, start notification from the shared repo.
- F13-T17: settings are the shared `SleepPreferences`, stored by the shared `PreferencesDefaults` (0.33.0).
- F13-T16: HealthKit and the raw log wrap shared 0.32.0 behaviour (`SleepHealthKit`, `SleepFiles`), the same code as SleepGuard.
- F13-T15: ADRs 0010–0012, architecture doc, README, AGENTS/CLAUDE, workflow, feature doc `docs/features/f13-architecture-review.md`. F13 done.

### Technical Details
- 0.30.0 adds `DetectionOutput.interruptionGap`; `RecordingSession` records it as a `.interruption` gap. The night detail's "recording paused" banner counts melody gaps only (`melodyGapsDuration`), because interruptions are reported separately.
- `Container.saveRules` is Debug 120 s / Release `.standard` (30 min). This app owns the choice; the shared rule carries no build configuration. Use cases and view models take it as an init parameter defaulting to `.standard`, and the two "too short" alerts read their minutes from it.
- T2: `SessionRecord.scoreVersion` (additive, "" = stale). `RefreshStaleSummaries` reads stale ids (no events), loads each night, recomputes and writes summaries in batches of 20 through `updateSummaries` (one save, one list update per batch). It runs in `AppCoordinator`'s recovery task, after the interrupted-night offer and before the storage limits; the briefing waits for that task.

### Files Changed
- `Packages/*/Package.swift`, `Packages/*/Package.resolved`, `Project.swift`: pin 0.30.0
- `SleepDomain/Recording/RecordingSession.swift`: interruption gaps
- `SleepDomain/UseCases/CommitSession.swift`, `ShouldAskForProfile.swift`: take `SaveRules`
- `RecordingFeature/SessionSummaryViewModel.swift`, `SessionSummaryViewController.swift`, `LiveRecordingModel.swift`, `BedsideClockViewController.swift`, `BedsideClockViewModel.swift`: `SaveRules`
- `SessionDetailFeature/NightDetailItems.swift`, `NightDetailController.swift`: melody-only gap banner
- `AppShell/Container+AppShell.swift`, `Recording/RecordingFactory.swift`: register and pass `saveRules`
- Tests: `CommitSessionTests`, `LiveRecordingModelTests`, `RecordingViewModelsTests`
- T2: `Ports/SessionRepository.swift`, `UseCases/RefreshStaleSummaries.swift` (new), `CommitSession.swift`, `LoadSessionDetail.swift`, `FakeSessionRepository.swift`, `Records.swift`, `RecordMapping.swift`, `SwiftDataSessionStore.swift`, `Container+AppShell.swift`, `AppCoordinator.swift`, `Debug/SampleNights.swift`; tests `RefreshStaleSummariesTests` (new), `CommitSessionTests`, `UseCaseTests`, `SwiftDataSessionStoreTests`, `SettingsStoresTests`
- T3: `LoadSessionDetail.swift` (+ `EnrichNightWithStages`), `SessionRepository.swift`, `FakeSessionRepository.swift`, `SwiftDataSessionStore.swift`, `SessionDetailRoutes.swift`, `SessionDetailViewModel.swift`, `Container+AppShell.swift`, `HistoryFactories.swift`; tests `UseCaseTests`, `SessionDetailViewModelTests`, `SwiftDataSessionStoreTests`
- T4: `SwiftDataSessionStore.swift`; test `SwiftDataSessionStoreTests`
- T6: `Ports/AudioCapture.swift` (`CaptureEvent`), `RecordingSession.swift`, `FakeAudioCapture.swift`, `EngineAudioCapture.swift`, `CaptureProcessor.swift`, `README.md`; tests `RecordingSessionTests`, `SettingsUseCaseTests`, `CaptureTests`, `LiveRecordingModelTests`
- T7: `RecordingSession.swift`; test `RecordingSessionTests` (+ `GatedCheckpointStore`)
- T9: `Navigator.swift`, `ScreenController.swift`, `NavigatorSpy.swift`, `StatisticsFlow.swift`, `SettingsFlow.swift`, `RecordingFlow.swift`, `NightDetailNavigation.swift`; tests `NavigatorTests`, `NavigatorInAppTests`, `HistoryFlowTests`, `SettingsFlowTests`, `SnoreInterrupterFlowTests`
- T13: `SleepDomainTestSupport/PortContracts.swift` (new), `FakeSessionRepository.swift`, `Adapters/Package.swift`; tests `PortContractTests` (Core, SleepPersistence), `MelodyStoreContractTests`
- T14: `ScreenController.swift`, `NightsListController.swift`, `NightDetailController.swift`, `scripts/check-layering.py`, `scripts/run-tests.sh`, `.github/workflows/ci.yml`; test `SessionsTabInAppTests`
- T5: manifests + `Package.resolved` + `Project.swift` (0.31.0), `Container+AppShell.swift` (`StoreOpening`), `AppCoordinator.swift`, `OnboardingFeature/StoreUnavailableViewController.swift`, `StoreUnavailableViewModel.swift` (new); tests `StorageAndSampleNightsTests`, `OnboardingFlowTests`, `HistoryFlowTests` (`Container.test`). Shared: `StoreUnavailableContent` + gallery + tests, strings, `Night.swift`, README
- T8: `Composition/AppComposition.swift` (new), `AppShell.swift`, `Container+AppShell.swift`, `AppCoordinator.swift`, `MainTabCoordinator.swift`, every `*Flow.swift`, `NightDetailNavigation.swift`, `scripts/check-layering.py`, `docs/adr/0009-typed-composition.md`; AppShell tests (construction through `AppComposition`), hosted tests (`HostedApp.container()`, `BrandBootstrapTests`)
- T10: `Recording/RecordingFlow.swift`, `Recording/InterrupterSettingsNavigation.swift` (new), `Recording/NightLifecycle.swift` (new); tests `NightLifecycleTests` (new), `SnoreInterrupterFlowTests`
- T11: `SessionRepository.swift`, `DeleteSession.swift` (+ `DeleteSessions`), `FakeSessionRepository.swift`, `PortContracts.swift`, `SwiftDataSessionStore.swift`, `HistoryDependencies.swift`, `HistoryViewModel.swift`, `HistoryViewController.swift`, `ScreenChrome.swift`, `ScreenController.swift`, `ThemedHosting.swift` (new), `Container+AppShell.swift`, `HistoryFactories.swift`, `NightDetailNavigation.swift`; tests `UseCaseTests`, `HistoryViewModelTests`, `ScreenControllerTests`, `PersonalizationFlowTests`, `BrandBootstrapTests`
- T12: `Routing/AppRoute.swift` (new), `AppCoordinator.swift`, `MainTabCoordinator.swift` (`NightDetailHosting`, `select`), `HistoryFlow.swift`, `StatisticsFlow.swift`, `AppComposition.swift`, `Apps/Shared/Sources/SceneDelegate.swift`; test `DeepLinkTests` (new)
- T15: `docs/adr/0010-stored-nights.md`, `0011-detection-input.md`, `0012-deep-links.md` (new), `docs/ARCHITECTURE.md` (with the owner's two renames), `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/CODING_WORKFLOW.md`, `docs/Roadmap.md`, `docs/features/f13-architecture-review.md` (new)
- T16: manifests and `Package.resolved` (0.32.0), `Project.swift`, `SleepHealth/SleepHealth.swift`, `SleepPersistence/Store/RawLogFileWriter.swift` (new; `FileRawLogWriter.swift` removed), `SleepPersistence.swift`, `Adapters/Package.swift`, `scripts/check-layering.py`; tests `HealthKitStageTests`, `SettingsStoresTests`
- T17: manifests and `Package.resolved` (0.33.0), `Project.swift`, `SleepDomain/Settings/AppPreferences.swift`, `SleepPersistence/Store/UserDefaultsPreferencesStore.swift`, `Adapters/Package.swift`, `scripts/check-layering.py`
- Docs: `FeatureTracker.md`, `trackers/f13-architecture-review.md`, this fragment

### Architecture Decisions
- ADR 0010 stored nights (versioned scores, one writer, store unavailable, all-or-none delete); ADR 0011 detection input (20 Hz, interruptions, writes off the sample path); ADR 0012 links.
- T8: ADR 0009, one composition per brand; flows take what they use.
- T4: the nights store stays the database's only writer; cross-context observation is deferred until a second writer exists (documented in the store).
- None new beyond that. The save minimum is the app's composition choice (shared 0.30.0's `SaveRules`).

### Build Status
- Every task: all four brands build on the pinned release (`TUIST_SHARED_RELEASE=1`), every lane passes, layering, view size and strings checks pass, SwiftFormat clean on changed files.
- Final: Core 81, Adapters 51, Presentation 19, Features 52, AppShell 88 package tests; 13 in-app tests per brand.
- Simulator: a pre-change store (14 nights) opened and was re-scored (T2); a corrupt store showed the store-unavailable screen and was kept byte for byte, then restored (T5); a link reached the app but iOS's "Open in…?" prompt couldn't be tapped (T12).
- Flake seen once: `PlayerInAppTests` timed out in one full Dawn run; passed on reruns.

### Suggested Branch
`feature/f13-architecture-review` into `main` (task branches `feature/f13/t1-…` to `feature/f13/t15-docs` already merged into it).

### Suggested Commit
Each task is its own commit (`F13-T# — …`, no AI trailer). The pull request into main:
```
F13 — Architecture review fixes

- Shared 0.31.0; SaveRules
- Versioned scores refreshed at launch; read-only detail; safe store failures; all-or-none day delete
- 20 Hz detection input, calls as gaps, writes off the sample path
- AppComposition per brand, flows take what they use; navigator races; RecordingFlow split
- Deep links; port contracts; compile-time screen bans; cheaper CI
- ADRs 0009–0012
```

### Next Session
- Owner: merge `feature/f13-architecture-review` into main; one real night on a device (20 Hz cadence, a call as a gap, resume after a call, thermal logs).
- F9-T4: the brands' screenshots.

### Open Questions
- Should the three pre-existing SwiftFormat failures on `main` be fixed in a separate small PR?
- `COMPARISON.md`'s line counts date from F12; refresh them?
