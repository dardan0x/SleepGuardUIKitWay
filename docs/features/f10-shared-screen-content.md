# F10 — Shared screen content

Every screen both apps show now draws its loaded layout from one place, the shared `SleepGuardContentKit`. A layout fix is made once and reaches SleepGuard and this app with a release. What stays in each app is what makes it that app: loading and state, dependencies, navigation, alerts and sheets, the navigation bar. In SleepGuard this was F25. Decided with the owner (ADR 0005 here, ADR 0006 there).

## The three layers

| Layer | What it is | Where |
|---|---|---|
| Components | Gauge, stat card, timeline, rows, buttons, waveform | `SleepGuardDesignKit` |
| Screen content | One screen's loaded layout: values and actions in, drawing out | `SleepGuardContentKit` |
| Screens | Loading and `ViewState`, `Dependencies`, `Routes`, alerts, the bar | Each app |

**The test:** a view that can be rendered from plain values alone is shared; one that needs a port, a use case, a route, an alert or a sheet is a screen.

## Files

| File | Purpose |
|---|---|
| `../SleepGuardShared/Sources/SleepGuardContentKit/Statistics/*` | Dashboard, Trends, Calendar, Last 7 Nights, empty and loading content (0.17.0) |
| `../SleepGuardShared/Sources/SleepGuardContentKit/Nights/NightsListContent.swift` | Nights list, day card, empty and loading (0.18.0) |
| `../SleepGuardShared/Sources/SleepGuardContentKit/Nights/NightDetailContent.swift` | Night detail (stages and footer slots), events grid (0.19.0) |
| `../SleepGuardShared/Sources/SleepGuardContentKit/Player/PlayerContent.swift` | Player card and content (0.20.0) |
| `../SleepGuardShared/Sources/SleepGuardContentKit/Recording/RecordingContent.swift` | Prestart (options slot), bedside clock (banner and overlay slots), summary (0.21.0) |
| `../SleepGuardShared/Sources/SleepCore/Statistics/NightMonth.swift` | Nights by month and day (0.18.0) |
| `../SleepGuardShared/Sources/SleepCore/Night/NightEventList.swift` | `EventFilter`, `EventListRow` (0.19.0) |
| `../SleepGuardShared/Sources/SleepCore/Playback/WaveformAccumulator.swift` | Waveform math (0.20.0) |
| `../SleepGuardShared/Sources/SleepGuardDesignKit/Components/ClipWaveform.swift` | The waveform view, replacing `PlayerProgress` (0.20.0) |
| `Packages/Core/Sources/SleepDomain/Ports/ClipWaveformSource.swift`, `Packages/Adapters/Sources/SleepAudio/FileWaveformSource.swift` | The waveform reaches this app |
| `Packages/Features/Sources/*Feature/*Screen.swift` | Screens host the content; layout files and their render tests removed |
| `docs/adr/0005-shared-screen-content.md` | The decision |
| SleepGuard: `Statistics`, `Recordings`, `SleepSession` containers; `SessionDetailModel`; `WaveformGenerator`; `PrestartOptions`, `ShortEventsButton` (slot views) | Host the same content |

## Decisions along the way (with the owner)

- Snoring rows show the episode's start (SleepGuard showed its longest event's).
- The event filter offers all four kinds once a night has two (SleepGuard's rule).
- The clip waveform comes to this app (a port and an adapter), and the player card is shared whole.
- SleepGuard's calendar line is localized ("62 out of 100", was "score 62" in English only).

## Edge cases

- **App-only extras** (sleep stages, short events, melody rows and overlay, debug sections) go through `@ViewBuilder` slots or stay in the app; never a flag naming an app.
- **SleepGuard's faulting rule:** content takes values the container chose (a period, a month's grid, a day's stats), so SleepGuard still chooses nights without reading events.
- **Render tests:** `ImageRenderer` can't draw UIKit-backed views (`List`, `ScrollView` contents, `Toggle`, segmented `Picker`). The tests draw the part inside them; the lists are checked in the apps.
- **Release checks:** the in-app lanes build `../SleepGuardShared` unless `TUIST_SHARED_RELEASE=1`.

## What stays per app, on purpose

- This app: `SessionDetailStateViews` (loading and error differ from SleepGuard's), state owners (`ClipPlaybackModel`, `LiveRecordingModel`), everything in `AppShell`.
- SleepGuard: containers and their headers, the error states only it has, debug and PDF features, the Snore Interrupter's views (F8 decides), `StatBox` and `WaveformShape` (used only by its debug sections, so not moved after all), `PlayerLoadingSkeleton`. Unused now and kept at the owner's choice: `SessionSummaryTimeline.swift`, `SessionSummaryHeader(session:scoreConfig:)`.

## Open

- The player's bars cover the current clip while its playhead and times cover the whole episode (as SleepGuard always did). Worth a decision.
- SleepGuard's adopted screens haven't been checked on screen: the morning briefing sheet covers the app at launch.

## Tasks completed

F10-T1 decision · F10-T2 Statistics · F10-T3 nights list · F10-T4a night detail · F10-T4b player and waveform · F10-T5 recording screens · F10-T6 review and docs.
