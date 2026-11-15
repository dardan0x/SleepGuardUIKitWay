# F4 — Statistics

The Statistics tab shows the latest night (score, stats, "last night" or "last time"), the week strip and the last 7 nights' scores, updating live. From it the user opens Trends (week or month), Last 7 Nights and the calendar, and from those a night's detail. Every number comes from the shared statistics rules in `SleepCore`, which SleepGuard uses too.

## Files

| File | Purpose |
|------|---------|
| `../SleepGuardShared/Sources/SleepCore/Statistics/*` | `NightDashboard` (+ week strip), `NightDay` / `NightDayStats`, `ScoreTrend`, `NightPeriod`, `CalendarMonth` (0.7.0, 0.8.0) |
| `../SleepGuardShared/Sources/SleepCore/Night/NightSummary.swift` | `loudestIntensity`, `snoringShare`, `snoringLevel` |
| `../SleepGuardShared/Sources/SleepGuardDesignKit/Components/*` | `WeekStrip` (0.8.0); `SnoringBarChart`, `SnoringDayBars`, `SnoringLegend`, `StatTile`, `CenteredStatTile`, `PillPicker`, `MonthHeader`, `CalendarMonthGrid`, `NightCard`, `DayRow` (0.9.0) |
| `Packages/Adapters/Sources/SleepPersistence/Records/*` | `SessionRecord.loudestIntensity` stored with the summary |
| `Packages/Features/Sources/StatisticsFeature/StatisticsScreen.swift` | Dashboard: `Dependencies`, `Routes`, loading / empty / loaded |
| `Packages/Features/Sources/StatisticsFeature/{Trends,LastSevenNights,Calendar}Screen.swift` | The three pushed screens; `NightListRoutes` |
| `Packages/Features/Sources/StatisticsFeature/Views/*` | Each screen's content, state views |
| `Packages/AppShell/Sources/AppShell/Statistics/{StatisticsComposers,StatisticsFlow}.swift` | Build the screens; the tab's navigation |
| `Packages/AppShell/Sources/AppShell/History/NightDetailNavigation.swift` | Opening a night from any tab (detail, events sheet, delete) |
| `Packages/AppShell/Sources/AppShell/Coordinators/{AppCoordinator,MainTabCoordinator}.swift` | Statistics tab; start recording goes to `AppCoordinator` |
| `Apps/HostedTests/StatisticsTabInAppTests.swift` | The real tab per brand |
| SleepGuard: `Packages/Statistics/**`, `Packages/Models/Sources/Data/SleepSession+Night.swift` | SleepGuard's Statistics on the same rules (`nightSummary`, `summaryWithoutEvents`) |

## Routes

| From | Route | To | How |
|------|-------|----|-----|
| Dashboard | calendar bar button | Calendar | Push |
| Dashboard | `showTrends` ("View month") | Trends | Push |
| Dashboard | `showLastSevenNights` ("See all") | Last 7 Nights | Push |
| Dashboard / empty | `startRecording` | `AppCoordinator.startRecording()` | Logged until F7 |
| Last 7 Nights, Calendar | `openNight` | Night detail | Push (`NightDetailNavigation`) |

## State

| State | Where | Lifetime |
|-------|-------|----------|
| Dashboard and the `now` it was made with | `StatisticsScreen` `@State` | Screen; refreshed on every store change |
| Nights | `TrendsScreen`, `LastSevenNightsScreen`, `CalendarScreen` `@State` (`NightsState`) | Screen |
| Week or month | `TrendsContent` `@State` | Screen |
| Shown month, selected day | `CalendarContent` `@State` | Screen |

## Edge cases

- **No nights:** the dashboard shows the empty state; the other screens show zeros, as SleepGuard does.
- **Several nights on one day:** counted as one day (average score, summed snoring); the day row opens its first night.
- **Bedtime after midnight:** "last time", not "last night" (judged by start).
- **Night without events:** no calendar dot; quiet bar colour in Trends; "Quiet" in the selected-night card.
- **Fewer than 8 recorded days:** no week-over-week trend.
- **SleepGuard performance:** choosing nights never reads events there; full summaries only for nights shown.

## Tasks completed

F4-T1 statistics rules in `SleepCore` · F4-T2 SleepGuard on the shared rules · F4-T3 dashboard (week-strip rule, store column) · F4-T4 Trends, Last 7 Nights, Calendar (kit components) · F4-T5 composers and `StatisticsFlow`.
