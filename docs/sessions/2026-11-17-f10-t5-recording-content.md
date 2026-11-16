
### Completed
- F10-T5: the prestart, bedside clock and summary host the shared recording content.

### Technical Details
- The bedside content takes the time as a value: this app ticks it with a `TimelineView`, SleepGuard with its own loop. Stop's rule (too early to keep) stays in each screen.
- The render tests draw the scrolling parts on their own; drawn inside a `ScrollView` they came out blank (`ImageRenderer` can't draw UIKit-backed scroll views), which a first version of the tests didn't catch.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Features/Sources/RecordingFeature/{RecordingPrestartScreen,BedsideClockScreen,SessionSummaryScreen}.swift` | Host the shared content |
| `Packages/Features/Package.swift` | `RecordingFeature` uses the content kit |
| Package manifests, `Package.resolved`, `Project.swift` | Shared `0.21.0` |
| `docs/trackers/f10-shared-screen-content.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | T5 done |

### Build Status
- Against the local shared checkout, then on shared `0.21.0` (in-app lanes with `TUIST_SHARED_RELEASE=1`): every lane passes; layering, view size, format pass.

### Next Session
- F10-T6: review and feature doc.
