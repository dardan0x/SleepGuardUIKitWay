
### Completed
- F10-T3: the nights list. Grouping is SleepCore's `NightMonth`; the list is the shared `NightsListContent`; `HistoryScreen` keeps loading, the delete confirmation and routing.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Features/Sources/HistoryFeature/HistoryScreen.swift` | Hosts the shared list content; `NightMonth` / `NightDay` |
| `Packages/Features/Package.swift` | `HistoryFeature` uses the content kit; `HistoryFeatureTests` removed |
| Package manifests, `Package.resolved`, `Project.swift` | Shared `0.18.0` |
| Deleted: `HistorySections.swift`, `Views/HistoryLoadedView.swift`, `Views/HistoryDayRow.swift`, `Tests/HistoryFeatureTests/*` | Rule and drawing are shared, with their tests |
| `docs/trackers/f10-shared-screen-content.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | T3 done |

### Build Status
- Against the local shared checkout, then on shared `0.18.0`: every lane passes (in-app tests for the three brands); layering and view size pass.

### Next Session
- F10-T4: night detail, events sheet and player content.
