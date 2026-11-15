
### Completed
- F4-T3: Statistics dashboard screen (`StatisticsFeature`), live from the repository, with empty and loading states.
- Two more rules found in SleepGuard's dashboard view, moved to shared for 0.8.0: the week strip (`NightDashboard.week(now:)`) and `NightSummary.snoringShare` / `snoringLevel`; plus the kit's `WeekStrip`. SleepGuard's strip uses the rule.

### Technical Details
- The screen keeps `NightDashboard` and the `now` it was made with, so "last night" and the week strip agree.
- Routes: start recording, Trends ("View month"), Last 7 Nights ("See all"). The calendar button goes in the navigation bar with the flow (F4-T5).
- The detail header now uses `NightSummary.snoringShare` instead of its own division.

### Build Status
- Against the local shared checkout: all package lanes pass (Features: Statistics 2 renders, plus History and Session Detail); checks and format pass. Shared: SleepCore 100, kit 6, strings 2.
- Renders reviewed: dashboard in two themes, empty state.
- Bumped to shared 0.8.0: package lanes, in-app tests for all three brands, checks and format pass against the release.

### Next Session
- F4-T4: Trends, calendar, Last 7 Nights screens.
