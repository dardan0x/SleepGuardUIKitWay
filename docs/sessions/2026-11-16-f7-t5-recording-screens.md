
### Completed
- F7-T5a (shared 0.16.0): the recording screens' presentational pieces in the kit, `NightTimeline(night:)`, `Night.minimumSaveDuration`; SleepGuard draws with them (its branch `feature/shared/f7-t5-recording-components`, 9 files deleted with approval).
- F7-T5b: `RecordingFeature`: `RecordingPrestartScreen`, `BedsideClockScreen` with `LiveRecordingModel`, `SessionSummaryScreen`.
- Countdown moved to F8 with the start delay, as decided for F7.

### Technical Details
- The screens follow SleepGuard's layout and alerts. Everything platform-specific (microphone prompt, charging, Settings link, idle timer, commit) reaches them as closures or values, so the feature stays free of UIKit.
- `LiveRecordingModel` owns the `RecordingSession`; the screen's `.task` runs it, a `TimelineView` ticks the clock once a second.
- A stop that races the samples: an event that starts after the microphone stopped gets no clip (there's no audio left to write). The model test waits for the clip to start, as a real night does.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Features/Package.swift` | `RecordingFeature` and its tests |
| `Packages/Features/Sources/RecordingFeature/RecordingRoutes.swift` | Dependencies and routes for the three screens |
| `Packages/Features/Sources/RecordingFeature/RecordingPrestartScreen.swift` | Prestart |
| `Packages/Features/Sources/RecordingFeature/LiveRecordingModel.swift` | State owner for the night in progress |
| `Packages/Features/Sources/RecordingFeature/BedsideClockScreen.swift` | Bedside clock |
| `Packages/Features/Sources/RecordingFeature/SessionSummaryScreen.swift` | Summary |
| `Packages/Features/Tests/RecordingFeatureTests/LiveRecordingModelTests.swift` | 4 tests |
| `docs/trackers/f7-recording-detection.md`, `docs/trackers/f8-remaining-features.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | T5 done; countdown to F8 |

### Build Status
- Against the local shared checkout: Features package tests pass (recording tests 3× clean); layering, view size and format pass.
- On shared `0.16.0`: every lane passes (Core macOS, each package standalone, in-app tests for the three brands).
- Not checked on screen: the shell shows these screens from T6. Every kit piece's render was checked in both themes.

### Next Session
- F7-T6: `RecordingFlow` (full-screen modal from `AppCoordinator`), `CommitSession`, discard with clip cleanup, idle timer; then the simulator and device check.
