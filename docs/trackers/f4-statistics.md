# F4 — Statistics

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P1 |
| **Milestone** | M2 |
| **Blocked By** | F2 |
| **Started** | 2026-11-14 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The user sees last night's summary and a seven-night chart on the dashboard, and can open trends, a calendar and the last seven nights.

## Tasks

| ID | Task | Type | Status | Depends On | Module | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F4-T1 | Statistics rules in `SleepCore` (shared 0.7.0): dashboard, day summaries, week-over-week trend, period stats, calendar month; `NightSummary.loudestIntensity` | Domain | Done | F2 | Shared repo | SleepGuard's test cases pass with the same numbers |
| F4-T2 | SleepGuard's Statistics uses the shared rules; its in-view copies removed | Refactor | Done | F4-T1 | SleepGuard | All SleepGuard tests pass; no visual change |
| F4-T3 | Dashboard screen (the store's loudest-intensity column landed in F4-T1) | UI | Done | F4-T1 | SleepPersistence, StatisticsFeature | `ViewState` with empty state; matches SleepGuard |
| F4-T4 | Trends, calendar, last 7 nights screens | UI | Done | F4-T3 | StatisticsFeature | Swift Charts; every number comes from the shared rules |
| F4-T5 | Composers and `StatisticsFlow`; "start recording" intent goes to `AppCoordinator` | Shell | Backlog | F4-T3, F4-T4 | AppShell | Flow tests with `NavigatorSpy` |

## Notes

- 2026-11-14: the statistics rules go to the shared repo (decided with the user), so SleepGuard and SleepGuardUIKitWay compute every number the same way. They work on `NightSummary` values (no events), plus a new `loudestIntensity` (loudest of any event; `nil` when the night has none), which the calendar colours, trend bars, last-7-nights rows and "loud nights" need.

## Task Details

### F4-T1 — Statistics rules in the shared repo (done 2026-11-14; shared 0.7.0)
- [x] `SleepCore/Statistics`: `NightDashboard` (latest night, its day's score and count, 7 most recent, "last night"), `NightDay` / `NightDayStats` (nights per start day, totals, last 7 recorded days, best/worst), `ScoreTrend.weekOverWeek`, `NightPeriod` (last week/month, averages, best/worst), `CalendarMonth` (month nights, average, loud nights, 42-day grid, day lookup)
- [x] `NightSummary.loudestIntensity` (any event's loudest; `nil` without events); `SnoreIntensity` is `Comparable`
- [x] 25 tests: SleepGuard's 13 dashboard and week-over-week cases with the same numbers, plus days, last 7, period, calendar, loudest intensity
- Ported exactly, including integer averages, grouping by start day (a night across midnight belongs to the day it started), ties (best = last max, worst = first min), and "last night" judged by start.

### F4-T2 — SleepGuard uses the shared rules (done 2026-11-14; SleepGuard branch `feature/shared/f4-t2-shared-statistics`)
- [x] Dashboard, week-over-week, Last 7 Nights, Trends, calendar and mini chart call the shared rules; the views keep their types and layout
- [x] Two mappings on `SleepSession`: `summaryWithoutEvents` (cached fields, no faulting) chooses nights; `nightSummary` (reads events) only for the nights shown. The dashboard and trend stay event-free; Last 7 Nights now reads fewer events than before
- [x] All 8 SleepGuard suites pass with no existing test changed (Statistics 18, Models 80 with 3 new); app builds; AGENTS.md/CLAUDE.md, ADR 0004, overview updated
- Not checked on screen with real data (Trends, calendar and Last 7 Nights had no tests before).

### Store column (landed with F4-T1)
- [x] `SessionRecord.loudestIntensity` (optional, additive) written and read with the summary; unknown values read as `.quiet`. Found by the store's observe test failing on 0.7.0 (the stored summary dropped the new field).
- Simulator stores seeded before this have `nil` for existing nights (no events colour) until re-seeded; the app isn't in production.

### F4-T3 — Dashboard screen (done 2026-11-14; shared 0.8.0)
- [x] `StatisticsFeature`: `StatisticsScreen` + `StatisticsDependencies` (repository) + `StatisticsRoutes` (start recording, Trends, Last 7 Nights); `ViewState` loading / empty / loaded, live from `observeSummaries()`
- [x] Loaded: week strip, score gauge (the day's score), "LAST NIGHT" / "LAST TIME" / "n RECORDINGS", date and times, kit `SessionStatsGrid`, "Last 7 Nights" chart with "See all", Start Recording pinned at the bottom
- [x] Empty: invitation to record, Start Recording
- [x] Found two more rules inside SleepGuard's dashboard view and moved them to shared (0.8.0): the week strip (`NightDashboard.week(now:)`) and `NightSummary.snoringShare` / `snoringLevel` (over 15% loud, over 5% light); kit `WeekStrip`. SleepGuard's strip uses the rule (its branch `feature/shared/f4-t3-week-strip-rule`)
- [x] Detail header uses `NightSummary.snoringShare` instead of its own division
- [x] Renders of the dashboard (two themes) and the empty state, reviewed
- Not here: title and calendar button in the navigation bar (F4-T5, UIKit owns the bar; SleepGuard draws its own header with a "Calendar" capsule), sleep-stage breakdown (F8).

### F4-T4 — Trends, Calendar, Last 7 Nights (done 2026-11-15; shared 0.9.0)
- [x] `TrendsScreen`: week/month picker, average snoring, a bar per night (loudest colour), legend, average/best/worst/total events (`NightPeriod`)
- [x] `LastSevenNightsScreen`: date range, average score and week-over-week trend, snoring per day, best/worst day, every day as a row that opens its first night (`NightDayStats`, `ScoreTrend`)
- [x] `CalendarScreen`: month header, 6-week grid with a dot per night with events, month stats, selected night card that opens it (`CalendarMonth`)
- [x] `NightListRoutes.openNight` for Last 7 Nights and the calendar; live from `observeSummaries()`
- [x] Built straight from new kit components (shared 0.9.0): `SnoringLegend`, `StatTile`, `CenteredStatTile`, `PillPicker`, `SnoringBarChart`, `SnoringDayBars`, `DayRow`, `NightCard`, `MonthHeader`, `CalendarMonthGrid`; `DurationText` public. No rules found in these views (formatting and layout only).
- [x] Renders of all three in two themes (one reviewed per screen); tests for the loudness label and the best/worst text
- Differences from SleepGuard: "Today" sits in the month header (UIKit owns the bar, and a bar button can't reach the screen's state); the selected night reads "Quiet · 40 out of 100" (SleepGuard hardcodes the English word "score"); Trends bars stack nights with the same label, as SleepGuard's do.
