
### Completed
- F7 planned in detail (7 tasks, the core night; extras in F8), decided with the user.
- F7-T1: `SnoreClassifier` (with sensitivity presets), `SpeechClassifier`, `DetectionSensitivity` in `SleepCore` (0.14.0), from SleepGuard's detectors, with their test cases.
- F7-T2: SleepGuard's `SnoreDetector`, `SpeechDetector` and tracker use them (SleepGuard branch `feature/shared/f7-t2-shared-detection-rules`).

### Technical Details
- The detection state machine was already shared; with these, every detection rule both apps run lives once.
- This branch: plan and notes, and the 0.14.0 bump.

### Build Status
- Shared: SleepCore 121 (replay goldens unchanged). SleepGuard on 0.14.0: 8 suites unchanged, release build. This repo on 0.14.0: package lanes, in-app tests for all three brands, checks and format pass.

### Next Session
- F7-T3: capture adapter.
