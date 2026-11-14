# F3 — History → Session Detail

The Sessions tab lists every night by month, updating live. Tapping a night opens its detail: score, stats, timeline with recording gaps, the gap and low-battery banners, and its events with a category filter. "Show all" opens every event in a sheet. A night can be deleted from the list (swipe a day) or from the detail (confirmed), and the list updates itself. This is the reference slice for the UIKit shell: composers, a flow per tab, `NavigatorSpy` tests.

## Files

| File | Purpose |
|------|---------|
| `Packages/Features/Sources/HistoryFeature/HistoryScreen.swift` | List screen: `Dependencies` (repository, `DeleteSession`), `Routes` (`openNight`), `ViewState`, live `observeSummaries()`, delete confirmation |
| `Packages/Features/Sources/HistoryFeature/HistorySections.swift` | Month and day grouping (pure, tested) |
| `Packages/Features/Sources/HistoryFeature/Views/{HistoryLoadedView,HistoryDayRow}.swift` | List, loading and empty states; expandable day row (kit `NightRow`, `ScoreBadge`) |
| `Packages/Features/Sources/SessionDetailFeature/SessionDetailScreen.swift` | Detail screen: `Dependencies` (night id, `LoadSessionDetail`), `Routes` (`showAllEvents`), loading / loaded / error with retry |
| `Packages/Features/Sources/SessionDetailFeature/DetailEvents.swift` | `EventFilter`, `DetailEventRow.make` (one row per snoring episode, other events alone; pure, tested) |
| `Packages/Features/Sources/SessionDetailFeature/Views/*` | Header (gauge, kit `SessionStatsGrid`, disturbances), timeline + banners, filter and event list, state views |
| `Packages/Features/Sources/SessionDetailFeature/EventsSheetScreen.swift` | All events under the current filter as kit `EventCard`s |
| `Packages/AppShell/Sources/AppShell/History/HistoryComposers.swift` | Build the list, the detail (date title, delete) and the events sheet |
| `Packages/AppShell/Sources/AppShell/History/HistoryFlow.swift` | The Sessions tab: push detail, confirm and delete then pop, present and dismiss the sheet |
| `Packages/AppShell/Sources/AppShell/Coordinators/MainTabCoordinator.swift` | `TabFlow`; the Sessions tab uses `HistoryFlow` |
| `Packages/AppShell/Sources/AppShell/Storage/NoSleepStages.swift` | Stage source until HealthKit (F8) |
| `Packages/Presentation/Sources/ScreenKit/Navigator.swift` | `PresentationStyle.alert` |
| `Apps/HostedTests/SessionsTabInAppTests.swift` | The real tab per brand: list, push, sheet detents, close |
| `../SleepGuardShared` 0.5.0 | Delete-night confirmation strings |
| `../SleepGuardShared` 0.6.0 | Detail components in `SleepGuardDesignKit`: `SessionStatsGrid`, `NightTimeline`, banners, `EventRow`, `EventCard`, `ScoreBadge`, `NightRow`, `Palette.eventColor` |

## Routes

| From | Route | To | How |
|------|-------|----|-----|
| List | `openNight(NightSummary)` | Detail | Push (title: the night's date) |
| Detail | trash bar button | Confirmation | Alert through the navigator |
| Confirmation | Delete | List | Delete, then pop |
| Detail | `showAllEvents([DetailEventRow])` | Events sheet | Sheet, medium and large, own navigation bar |
| Events sheet | close bar button | Detail | Dismiss |

## State

| State | Where | Lifetime |
|-------|-------|----------|
| List months | `HistoryScreen` `@State` `ViewState`, fed by `observeSummaries()` | While the list is on screen |
| Day expanded | `HistoryDayRow` `@State` | Row |
| Pending day delete | `HistoryScreen` `@State` | Until confirmed or cancelled |
| Detail | `SessionDetailScreen` `@State` `ViewState` | Screen |
| Event filter | `SessionDetailContent` `@State` | Screen |
| Delete task | `HistoryFlow.deleting` | Cancelled with the flow |

## Edge cases

- **No nights:** empty state.
- **Several nights in a day:** the day row expands to list them; one night opens directly.
- **Detail fails to load:** error state with "Try again".
- **Delete fails:** the detail stays (logged); from the list, an error alert.
- **One kind of event:** no filter shown.
- **Micro-episodes (under 3 s):** no row and no timeline mark.
- **Detection paused (Snore Interrupter):** outlined block on the timeline, gap banner with the total.
- **Saved on low battery:** low-battery banner.
- **Night across midnight:** night rows show times only.
- **Large title over a hosted SwiftUI `List`:** UIKit doesn't create it (iOS 26.2); the list uses an inline title.

## Tasks completed

F3-T1 History list · F3-T2 session detail · F3-T3 composers and `HistoryFlow` (delete confirmed) · F3-T4 events sheet · F3-T5 detail components in the shared kit.
