
### Completed
- F4-T4: `TrendsScreen`, `LastSevenNightsScreen`, `CalendarScreen` in `StatisticsFeature`, live from the repository.
- Ten kit components in the shared repo for 0.9.0 (`SnoringLegend`, `StatTile`, `CenteredStatTile`, `PillPicker`, `SnoringBarChart`, `SnoringDayBars`, `DayRow`, `NightCard`, `MonthHeader`, `CalendarMonthGrid`), built there directly instead of moving them later.

### Technical Details
- Numbers: `NightPeriod`, `NightDayStats`, `ScoreTrend`, `CalendarMonth` (shared). The screens only format and lay out.
- `NightListRoutes.openNight` serves Last 7 Nights and the calendar; the flow pushes the night's detail (F4-T5).
- "Today" is in the month header, not the bar: UIKit owns the bar and a bar button can't reach the screen's state.

### Build Status
- Against the local shared checkout: all package lanes pass (Statistics: 2 dashboard renders, 3 screen renders, 2 text tests); checks and format pass. Shared: SleepCore 100, kit 7, strings 2.
- Bumped to shared 0.9.0 and tested against the release (see handover). SleepGuard needs no change (no new rules); it adopts the components in F24.

### Next Session
- F4-T5: composers and `StatisticsFlow` (tab, calendar bar button, pushes, open a night, start recording to `AppCoordinator`).
