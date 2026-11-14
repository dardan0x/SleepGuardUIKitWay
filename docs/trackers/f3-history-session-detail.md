# F3 — History → Session Detail

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P0 |
| **Milestone** | M2 |
| **Blocked By** | — |
| **Started** | 2026-11-14 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The user sees their nights grouped by month, opens one, reads its score, timeline and events, and can delete it. This is the reference slice: the first complete path from entity to screen, and the example every later feature copies.

## Tasks

| ID | Task | Type | Status | Depends On | Module | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F3-T1 | `HistoryFeature`: screen, state views, month grouping, swipe to delete | UI | Done | F2 | HistoryFeature | Live updates from `observeSummaries()`; no refetch on pop |
| F3-T2 | `SessionDetailFeature`: header, timeline, stats grid, event list with category filter | UI | Done | F2 | SessionDetailFeature | Matches the design; loads through `LoadSessionDetail` |
| F3-T3 | Composers and `HistoryFlow`: push detail, delete then pop | Shell | Done | F3-T1, F3-T2 | AppShell | Flow tests with `NavigatorSpy` |
| F3-T4 | Events sheet as a UIKit sheet presented by the flow | Shell | Done | F3-T3 | AppShell, SessionDetailFeature | Detents work; dismissal returns to detail |
| F3-T5 | Timeline, stats grid, legends, event row, score badge and night row in the design kit, fed by view-data structs; UIKitWay's own copies removed | UI | Backlog | F1-T4 | Shared repo | No domain types in the kit; a view change is made once |

## Task Details

### F3-T1 — History screen (done 2026-11-14)
- [x] New `Packages/Features` package, `HistoryFeature` module: `HistoryScreen` + `HistoryDependencies` (repository, `DeleteSession`) + `HistoryRoutes` (`openNight`)
- [x] `ViewState`: loading (redacted placeholder rows), empty, loaded. No error state: the list stream can't fail; a failed delete shows an alert
- [x] Live updates from `observeSummaries()`; re-subscribing on reappear yields the current list at once, so no loading flash
- [x] `HistorySections`: month, then day, newest first (SleepGuard's grouping); a day with several nights expands
- [x] Swipe to delete a day, confirmed by alert; deletes go through `DeleteSession`
- [x] Tests: 3 grouping tests, 1 render test (rows and empty state in two themes, renders differ); renders reviewed by eye
- Notes: dates and durations use system formatting (`7h 30m`), so no new strings. "1 events" comes from the shared string, which isn't plural-aware (SleepGuard shows the same); fix in the catalog separately. The full `List` can't be drawn outside a window; its layout is checked in the app in F3-T3.

### F3-T2 — Session detail screen (done 2026-11-14)
- [x] `SessionDetailFeature`: `SessionDetailScreen` + `SessionDetailDependencies` (night id, `LoadSessionDetail`) + `SessionDetailRoutes` (`showAllEvents`)
- [x] `ViewState`: loading (placeholder shapes), loaded, error with "Try again" (re-runs the load)
- [x] Header: score gauge, duration / snoring % / snore time / events, disturbances card when there are non-snoring events
- [x] Event filter (All / Snoring / Sleep talking / Noise), offered only when the night has more than one kind
- [x] Event rows: one per displayable snoring episode (its representative event, the episode's summed time), every other event alone; first 4, then "Show all"
- [x] Tests: 4 for filters and rows, 1 render in two themes (renders differ; reviewed by eye)
- [x] `SessionDetail` got a public initializer (previews and tests)
- Not here: navigation bar title and delete (F3-T3), events sheet (F3-T4), timeline and the gap / low-battery banners (F3-T5), play and share (F5).
- Note: the segmented filter is UIKit-backed and doesn't appear in `ImageRenderer` renders; checked in the app in F3-T3.

### F3-T3 — Composers and History flow (done 2026-11-14; shared 0.5.0)
- [x] `HistoryScreenComposer`, `SessionDetailComposer` (date title, delete in the bar), `HistoryFlow` (list → push detail → delete then pop), `TabFlow` protocol; Sessions tab uses `HistoryFlow`
- [x] Container: `sleepStagePort` (`NoSleepStages` until F8), `deleteSession`, `loadSessionDetail`
- [x] `HistoryRoutes.openNight` passes the `NightSummary` (title without waiting for the load)
- [x] Tests: 19 shell tests (flow: root, push detail with title and delete item, delete asks first, delete then pop, failed delete stays, no leak); ScreenKit 12 (alert style); in-app test in each brand drives the real Sessions tab and checks the pushed detail
- [x] On screen (simulator screenshots): list, detail, filter, ring, stat cards correct in SleepGuard and Nocturne
- [x] Large title: investigated (time-boxed). UIKit never creates the large-title view over the hosted `List` (bar at large height, only the inline label present); resizing the bar, a `List` placeholder and bar appearances ruled out. The list uses an inline title (decided 2026-11-14).
- [x] Delete from the detail asks first: `UIAlertController` ("Delete This Night?", Cancel / Delete) presented through the navigator (new `PresentationStyle.alert`); only Delete deletes. Two new strings in shared (`session.delete.confirmTitle`, `session.delete.confirmMessage`).
- Notes: screenshots taken by the app itself (`drawHierarchy`) showed a half-drawn ring and clipped cards that the simulator's own screenshots didn't: use `simctl io screenshot` for visual checks. Screens no longer paint their own background (the hosting controller does). Delete from the detail confirms first (unlike SleepGuard, decided 2026-11-14).

### F3-T4 — Events sheet (done 2026-11-14)
- [x] `EventsSheetScreen` (public, `SessionDetailFeature`): every row under the detail's current filter as a 3-column grid of `EventCardView` (start time, length in the event's colour)
- [x] `SessionDetailRoutes.showAllEvents` passes the rows on screen; `DetailEventRow` is public (init stays internal)
- [x] `HistoryFlow` presents it in its own navigation controller (title "Events", close button) at medium and large detents; close dismisses
- [x] One colour rule for rows and cards (`DetailEventRow.color(in:)`)
- [x] Tests: flow (present with detents, rows passed through, close dismisses); card render in two themes (reviewed); in-app in each brand: real sheet, detents, close returns to the detail
- Not here: Play on each card (F5). Card start-time line shrinks to fit (SleepGuard only shrinks the time), since three cards share 390 pt.

## Notes

- Rule (2026-11-14): a view that only takes values and draws them goes in the shared kit; a view that loads data, holds state or navigates stays in the app. F3-T5 widened to move `DetailEventRowView`, `ScoreBadge` and the night row along with the timeline, stats grid and legends.

- Port SleepGuard's `SessionGrouper` logic as a policy.
- Share and PDF export are not in this slice (F8).
