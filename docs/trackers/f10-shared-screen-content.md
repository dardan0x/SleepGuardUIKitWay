# F10 — Shared screen content

> Updated by the AI after every task in this feature. Task details are expanded when the task starts.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P1 |
| **Milestone** | M4 |
| **Blocked By** | F7 |
| **Started** | 2026-11-16 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The loaded layout of each screen exists once, in the shared repo's `SleepGuardContentKit`, and both apps host it. Screens (loading, dependencies, navigation, alerts, the navigation bar) stay in each app. Decided with the owner on 2026-11-16; see ADR 0005. In SleepGuard this is tracked as **F25 — Shared Screen Content**.

**The test:** a view that can be rendered from plain values alone is shared; one that needs a port, a route, an alert or a sheet stays in the app.

## Tasks

Each task from T2 on is one shared release, then SleepGuard adopts it, then this app does, with every lane on the release.

| ID | Task | Type | Status | Depends On | Where | Acceptance (short) |
|----|------|------|--------|------------|-------|--------------------|
| F10-T1 | Decision recorded: ADR here and in SleepGuard, the three-layer rule in both apps' AGENTS/CLAUDE, trackers, layering table | Docs | Done | F7 | Both apps | — |
| F10-T2 | `SleepGuardContentKit` product; Dashboard, Trends, Calendar, Last 7 Nights content; empty and loading placeholders | Shared / Refactor | Done | F10-T1 | Shared, both apps | `StatisticsFeature/Views/*` gone here; SleepGuard's Statistics screens host the same content |
| F10-T3 | Nights list content; `NightMonth` rule in `SleepCore` | Shared / Refactor | Done | F10-T2 | Shared, both apps | `HistorySections` and SleepGuard's `SessionGrouper` gone; both apps' grouping tests pass on the rule |
| F10-T4a | Night detail and events sheet content; `EventFilter` and `EventListRow` rules in `SleepCore` | Shared / Refactor | Done | F10-T2 | Shared, both apps | Detail views and `DetailEvents` gone here |
| F10-T4b | Player card and event list shared; clip waveform ported here (decided 2026-11-16: port now) | Shared / Adapter / Refactor | Done | F10-T4a | Shared, both apps | `PlayerScreen` hosts the shared player content with the waveform |
| F10-T5 | Prestart, bedside clock and summary content (slots for SleepGuard's melody rows and overlay) | Shared / Refactor | Done | F10-T2 | Shared, both apps | The three recording screens here are containers only |
| F10-T6 | Review: no screen-content view left in either app for the shared screens; docs final; feature doc | Docs | Backlog | F10-T3, T4, T5 | Both apps | — |

## Notes

- SleepGuard's content views read `SleepSession`. Its containers map to `SleepCore` values first (`summaryWithoutEvents`, `nightSummary`, `night`); lists must use the cached summaries (event faulting).
- Deleting SleepGuard files needs the owner's yes each time.
- SleepGuard keeps its `DesignSystem` package as its bridge to the shared kit (`AppTheme`, model adapters, re-exports). Its sleep-stage views move to the kit with F8-T3.
- F8 is built content-first (ADR 0005).

## Task Details

### F10-T5 — Recording screens (done 2026-11-17)
- [x] Shared (0.21.0): `PrestartContent` (options slot), `BedsideClockContent` (banner and overlay slots; the screen ticks `time` and decides Stop; `canStop`), `SessionSummaryContent`; their scrolling parts (`PrestartStack`, `SessionSummaryStack`) are what the render tests draw, since `ImageRenderer` can't draw inside a `ScrollView`
- [x] Here: the three `RecordingFeature` screens host the content; alerts, permission and charger checks, the `TimelineView` tick and the early-stop rule stay in the screens
- [x] SleepGuard F25-T5: prestart (delay and Snore Interrupter rows as `PrestartOptions` in the slot), bedside clock (melody disclaimer and overlay in the slots), summary host the same content. Kept at the owner's choice, now unused: `SessionSummaryTimeline.swift` and the `SessionSummaryHeader(session:scoreConfig:)` adapter
- No visible change intended in either app

### F10-T4b — Player with waveform (done 2026-11-16)
- [x] Shared (0.20.0): SleepCore `WaveformAccumulator` (SleepGuard's waveform math, fed in pieces; 4 tests); kit `ClipWaveform` (SleepGuard's bars, playhead, time labels, tap to seek, loading pulse; VoiceOver adjust ±15 s carried over from the old progress bar) replaces `PlayerProgress`; content `PlayerCard` (card with loading veil, explicit back / forward for SleepGuard's legacy player) and `PlayerContent` (card, enhanced audio, event list; 15 s skips through seek, `PlayerCard.position(skipping:)`), `PlayerClip`
- [x] Here: port `ClipWaveformSource` (SleepDomain) + `FakeClipWaveformSource`; adapter `FileWaveformSource` (SleepAudio, `AVAudioFile` → accumulator, off the caller's actor); `ClipPlaybackModel` reads the current clip's bars beside playback (`waveform`, `isLoadingWaveform`; a stale result is dropped; cleared for a clip without a file); `PlayerScreen` hosts `PlayerContent`; registration and composer
- [x] Tests: model waveform (3), file source on a generated clip (3)
- [x] SleepGuard F25-T4b: `ClipPlayerContent` hosts `PlayerContent`, `LegacyPlayerContent` hosts `PlayerCard`, `WaveformGenerator` uses the accumulator (3 files deleted, approved)
- Visible change here: the player shows the clip's waveform instead of a progress bar

### F10-T4a — Night detail (done 2026-11-16)
- [x] Decided with the owner: a snoring row shows the episode's start (SleepGuard showed its longest event's); the filter offers all four as soon as a night has two kinds of event (SleepGuard's rule; sleep talking only while detected); the waveform comes to this app now (T4b)
- [x] SleepCore (0.19.0): `EventFilter` (`includes`, `options(for:includeSleepTalking:)`) and `EventListRow` (`rows(for:filter:)`, `playback(in:)`); tests carry both apps' cases
- [x] Content: `NightDetailContent` (header, timeline, gap and low-battery banners, filter, first four events, Show all; optional Share; `stages` and `footer` slots) and `EventsGridContent`
- [x] Here: `SessionDetailScreen` and `EventsSheetScreen` host the content; `DetailEvents`, the loaded, header and timeline views and their tests removed; loading and error views stay (SleepGuard's differ)
- [x] SleepGuard F25-T4a: its detail hosts the same content (stages and the short-events button in the slots), `SessionDetailModel` uses the shared rules (3 files deleted, approved)
- Visible change here: the filter now offers all four kinds (was only those present)

### F10-T3 — Nights list (done 2026-11-16)
- [x] Shared (0.18.0): `NightMonth.months(from:)` in SleepCore (months, then `NightDay`s, newest first at every level), tests with both apps' grouping cases; content `NightsListContent` (month sections, swipe and long-press delete request), `NightDayCard` (SleepGuard's row), `NightsListEmptyContent`, `NightsListLoadingContent`; kit `NightRow` shows the night's length and a chevron (SleepGuard's expanded row)
- [x] Render tests for the day card, empty and loading content; the `List` itself can't be drawn by `ImageRenderer` (UIKit-backed), so it is checked in the apps
- [x] Here: `HistoryScreen` hosts the content and keeps the delete confirmation; `HistorySections`, `HistoryLoadedView`, `HistoryDayRow` and the `HistoryFeatureTests` target removed
- [x] SleepGuard F25-T3: same content and rule (6 files deleted, approved)
- Visible changes here, toward SleepGuard's design: the day shows the medium date ("16 Nov 2026"), the length as "7h 12 mins", a long press asks to delete, the chevron doesn't turn, expanded nights show their length and a chevron

### F10-T2 — Statistics content (done 2026-11-16)
- [x] Shared (0.17.0): product `SleepGuardContentKit` (re-exports the design kit); `StatisticsDashboardContent` (slot for an extra below the stats), `TrendsContent` + `TrendsRange`, `CalendarContent`, `LastSevenNightsContent`, `StatisticsEmptyContent`, `StatisticsLoadingContent`; gallery; render tests in both themes and text tests. `Theme.previewAlternate` made public for previews and tests
- [x] Content takes chosen values, not every night: the screen owns the range, month and selected day, and passes the period, the grid's nights, the day stats. That's what lets SleepGuard keep choosing nights without reading events
- [x] Here: the four screens host the content; `StatisticsFeature/Views/*` (5 files) and the two render-test files deleted (their content is tested in the shared repo); `StatisticsFeatureTests` target removed
- [x] SleepGuard F25-T2: its four screens host the same content (10 files deleted, approved)
- [x] Visible changes, approved: SleepGuard's calendar line is now localized ("62 out of 100"). Here: the empty state's button sits closer to its text (SleepGuard's spacing), the calendar's day title is "Monday, Nov 16" (SleepGuard's format)
- [x] Every lane against the local shared checkout; dashboard screenshot in the app unchanged


### F10-T1 — Decision recorded (done 2026-11-16)
- [x] ADR 0005 here; ADR 0006 in SleepGuard
- [x] AGENTS.md / CLAUDE.md in both apps: the three layers and the test
- [x] `check-layering.py`: features may import `SleepGuardContentKit`
- [x] Trackers: this file, dashboard, roadmap, F8 note; SleepGuard F25
