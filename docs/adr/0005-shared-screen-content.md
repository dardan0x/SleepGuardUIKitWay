# ADR 0005: Share screen content, keep screens

- **Status:** Accepted
- **Date:** 2026-11-16
- **Task:** F10

## Context

This app and SleepGuard already share rules (`SleepCore`), strings and UI components (`SleepGuardDesignKit`). After F7 a layout fix still had to be made twice, because each app arranges those components into screens on its own: SleepGuard's `StatisticsLoadedView` and this app's `StatisticsDashboardContent` are the same layout written twice, down to the "LAST NIGHT" label logic. The same is true of Trends, Calendar, Last 7 Nights, the nights list, the night detail, the player card and the three recording screens. One rule was duplicated too: grouping nights by month and day.

The owner asked whether every remaining SwiftUI view should move to the shared repo.

## Decision

View code has three layers. Only the middle one moves.

| Layer | What it is | Where it lives |
|---|---|---|
| Components | Gauge, stat card, timeline, rows, buttons | `SleepGuardDesignKit` (shared) |
| Screen content | One screen's loaded layout: values and action closures in, drawing out | `SleepGuardContentKit` (shared, new) |
| Screens | Loading and `ViewState`, dependencies, navigation, alerts and sheets, the navigation bar | Each app |

- **The test:** a view that can be rendered in a test from plain values alone is shared. One that needs a port, a use case, a route, an alert or a sheet is a screen and stays here.
- **A separate product, not the design kit.** The kit stays a design system with no product knowledge. Screen content knows the product (which stats the dashboard shows), so it gets its own product that depends on the kit and `SleepCore`. The kit can't import it.
- **Inputs.** `SleepCore` values and `() -> Void` actions. Never a port, a brand, or a flag naming an app.
- **App-only extras** (SleepGuard's sleep-stage breakdown, melody rows, share) go through an optional value or a `@ViewBuilder` slot. A screen the two apps want laid out differently is not shared.
- **This app's screens become thin.** `Screen` + `Dependencies` + `Routes` load and route; the body hosts the shared content. State views that only draw (empty, loading) are content too.
- **Rules follow the same line.** The month-and-day grouping moves to `SleepCore`.
- **New screens are built content-first.** For F8, SleepGuard's content moves to the shared product first; this app then adds only the screen and its flow.

## Consequences

- A layout fix to a shared screen is made once and reaches both apps after a release and a bump.
- A fix to loading, navigation or an alert is still made per app. That is the point: those are where the two architectures differ (SleepGuard: `@Query`, `@Injected`, `RouterPath`; here: ports, use cases, `Routes`, UIKit coordinators).
- Feature modules shrink to what is architecture. What a reviewer reads here is how a screen gets its data and where it goes next, not layout.
- Every layout change now needs a shared release.
- Not shared: state owners (`ClipPlaybackModel`, `LiveRecordingModel`; their rules already are), `ScreenChrome`, anything in `AppShell`.

## Alternatives

- **Share whole screens** behind a common data-source and navigation abstraction. Both apps would be forced into one architecture, which removes the reason there are two. Rejected.
- **Put screen content in the design kit.** The kit would mix tokens and components with product decisions and grow without a boundary. Rejected.
- **Leave it.** Two copies of every layout, drifting, and every F8 screen written twice. Rejected.
