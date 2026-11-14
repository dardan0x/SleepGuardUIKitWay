
### Completed
- F1-T5: `ScreenKit` in `Packages/Presentation`.
  - `HostingScreen<Content>`: the one `UIHostingController` subclass. Puts the brand `Theme` into the SwiftUI environment, paints `bgPrimary`, applies `ScreenChrome` to the navigation item, hides the bar when asked.
  - `ScreenChrome` / `BarItem`: title, large title, hidden bar, trailing icon items (accessibility label required).
  - `Navigator` protocol + `NavigationControllerNavigator`: set root, push, pop, pop to root, present (sheet with detents / full screen), dismiss the topmost. Each operation waits for a running transition to end rather than being dropped.
- Packages moved to `SleepGuardShared` 0.2.0; `ScreenKit` depends on `SleepGuardDesignKit`.

### Technical Details
- Waiting uses the controller's `transitionCoordinator` completion; presenting targets the topmost presented controller that isn't being dismissed.
- **Package tests can't present:** they run with no host app, so a test `UIWindow` has no scene and UIKit never completes a presentation. Two window-based tests hung the run (stopped at the owner's request). Replaced by tests of the presentation configuration (`configure(_:for:)`, internal for tests); real present/dismiss moves to F1-T6, inside the app.
- Test runs use `-test-timeouts-enabled YES` with a 30 s default / 60 s maximum per test, so a hang fails quickly.
- Child-containment helper deferred: no planned screen embeds SwiftUI inside UIKit content.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Presentation/Package.swift` | Shared 0.2.0 + design kit; test target |
| `Packages/Presentation/Sources/ScreenKit/{HostingScreen,ScreenChrome,Navigator}.swift` | New; placeholder file removed |
| `Packages/Presentation/Tests/ScreenKitTests/{HostingScreenTests,NavigatorTests}.swift` | 11 tests |
| `Packages/{Core,Adapters}/Package.swift`, `Package.resolved` | Shared 0.1.0 → 0.2.0 |
| `Packages/Presentation/Package.resolved` | New lockfile |
| `.gitignore` | Ignore Tuist's root `.package.resolved` |
| `docs/trackers/f1-foundation.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | Status |

### Build Status
- `ScreenKitTests`: 11 passed (simulator, 0.6 s).
- `SleepDomainTests`: 1 passed (macOS) against shared 0.2.0.
- **BUILD SUCCEEDED**: `SleepGuard`, `SleepGuardLite`, `Nocturne`. SwiftFormat clean.
- Not verified: presenting and dismissing for real (moved to F1-T6).

### Open Questions
- `bg-card` token (`#2C2C2E` in SleepGuard's CLAUDE.md vs `#22232B` in its code) still open.
