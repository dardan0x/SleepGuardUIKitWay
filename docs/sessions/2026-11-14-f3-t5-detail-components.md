
### Completed
- F3-T5: the night-detail components live in the shared `SleepGuardDesignKit` and UIKitWay uses them; the detail gains the timeline and the gap / low-battery banners. F3 is done (feature doc written).

### Technical Details
- New in the kit: `SessionStatsGrid`, `NightTimeline` + `TimelineMark`, `RecordingGapsBanner`, `LowBatteryBanner`, `EventRow`, `EventCard`, `ScoreBadge`, `NightRow`, `Palette.eventColor(_:intensity:)`, internal `DurationText`. All take values and `SleepCore` types; the kit now depends on `SleepCore`.
- Play / Share on rows and cards appear only when an action is passed (F5 will pass them).
- Formats follow SleepGuard so its adoption (F6 / SleepGuard F24) changes nothing visually: stat durations as a clock ("8:24:00").
- Fixed: night rows printed full dates for nights across midnight.
- Removed from UIKitWay: `DetailEventRowView`, `EventCardView`, `HistoryNightRow`, `ScoreBadge`, the header's own grid and its colour helper.
- Not moved: intensity legends (F4/F5), expandable day row (compare in F6/F24).
- Mistake caught: running `swiftformat` in the shared repo without a config reformatted 49 files; restored from git, new files formatted with SleepGuard's config. The shared repo has no `.swiftformat` of its own.

### Build Status
- Shared: SleepCore 72, design kit 6, strings 2 pass; kit renders in two themes reviewed.
- UIKitWay bumped to shared 0.6.0 (`bump-shared.sh 0.6.0`); tested against the release: see handover.

### Next Session
- Merge F3 into `main`, then F4 (Statistics).
