
### Completed
- F10-T2: the shared `SleepGuardContentKit` with the Statistics screens' content; this app's four Statistics screens host it (SleepGuard's too, F25-T2).

### Technical Details
- Content takes the values a screen chose (period, grid nights, day stats) and closures; the screens keep loading, state (range, month, selected day) and routes.
- The dashboard content has a `@ViewBuilder` slot below the stats; SleepGuard puts its sleep stages there.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Features/Package.swift` | `StatisticsFeature` uses `SleepGuardContentKit`; `StatisticsFeatureTests` removed |
| `Packages/Features/Sources/StatisticsFeature/{Statistics,Trends,Calendar,LastSevenNights}Screen.swift` | Host the shared content |
| Package manifests, `Package.resolved`, `Project.swift` | Shared `0.17.0` |
| `Apps/HostedTests/PlayerInAppTests.swift` | Waits for the player to stop after the sheet closes (timing fix) |
| Deleted: `StatisticsFeature/Views/*` (5), `Tests/StatisticsFeatureTests/*` (2) | Content and its render tests are in the shared repo |
| `docs/trackers/f10-shared-screen-content.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | T2 done |

### Build Status
- Against the local shared checkout: every lane passes (in-app tests for the three brands); layering, view size pass. Dashboard screenshot in the running app: unchanged.
- On shared `0.17.0`: every lane passes against the release. The first run had one failure in the SleepGuard brand's `PlayerInAppTests` (Lite and Nocturne passed): it checked "not playing" the moment the sheet was gone, but the player stops on the sheet's disappearance, a beat later. It passed 3 reruns as it was; the test now waits for the stop (as it waits for everything else), and the brand's in-app tests passed twice more.

### Next Session
- F10-T3: nights list content and `NightsByMonth`.
