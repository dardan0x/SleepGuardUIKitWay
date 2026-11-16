
### Completed
- F10-T4a: the night detail and the events sheet host the shared content; the event filter and list rows are SleepCore rules.

### Architecture Decisions
- With the owner: snoring rows show the episode start; the filter offers all four kinds once a night has two; the clip waveform is ported to this app now, as its own task (T4b).

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Features/Sources/SessionDetailFeature/SessionDetailScreen.swift` | Holds the filter; hosts `NightDetailContent`; routes take `EventListRow` |
| `Packages/Features/Sources/SessionDetailFeature/EventsSheetScreen.swift` | Hosts `EventsGridContent` |
| `Packages/Features/Package.swift` | `SessionDetailFeature` uses the content kit |
| `Packages/AppShell/Sources/AppShell/History/{HistoryComposers,NightDetailNavigation}.swift`, `Packages/AppShell/Tests/AppShellTests/HistoryFlowTests.swift`, `Apps/HostedTests/SessionsTabInAppTests.swift` | `EventListRow` |
| Package manifests, `Package.resolved`, `Project.swift` | Shared `0.19.0` |
| Deleted: `DetailEvents.swift`, `Views/{SessionDetailLoadedView,SessionDetailHeader,SessionDetailTimeline}.swift`, `Tests/.../{DetailEventsTests,SessionDetailRenderTests}.swift` | Rules and drawing are shared, with their tests |

### Build Status
- Against the local shared checkout: every lane passes (a first run stopped when the disk filled; `.build` caches removed with the owner's OK, rerun green).
- On shared `0.19.0`: package lanes pass; in-app lanes run with `TUIST_SHARED_RELEASE=1` (plain `tuist generate` builds the local shared checkout, which already held unfinished T4b work).

### Next Session
- F10-T4b: shared player card and event list; a waveform port and adapter here.
