# ADR 0001: UIKit shell, SwiftUI screens, no view models

- **Status:** Accepted
- **Date:** 2026-11-14

## Context

SleepGuard is all SwiftUI: `NavigationStack` per tab, a `RouterPath` in the environment, many screen-level `.sheet` modifiers. Two flows show the cost. The end-of-night summary and crash recovery are triggered by the Statistics tab's view observing a service, so they work only while that tab exists. And screen-level sheets are split between a route enum and local modifiers, so no single place knows what is on screen.

The conventional way to host SwiftUI in a UIKit shell is a per-screen composer, an `ObservableObject` view model, a routing protocol implemented by an app-side router, and one `UIHostingController` subclass per screen. Navigation ownership then tends to split: the router pushes some screens and forwards others to a coordinator.

## Decision

- **UIKit owns the app shell and all navigation.** Coordinators perform every push, pop, present and dismiss through a `Navigator` protocol.
- **Screens are SwiftUI in MV style.** A screen has `@State` and a `ViewState` enum. Its public surface is `Screen(dependencies:routes:)`: `Dependencies` holds ports, use cases and plain values; `Routes` holds `@MainActor` closures naming what the user asked for.
- **One generic `HostingScreen<Content>`** applies a `ScreenChrome` value (title, bar items) and injects the theme. UIKit owns the navigation bar.
- **One composer shape** in `AppShell`: resolve, build the screen, return a `UIViewController`.

## Consequences

- One owner for transitions. Recording, summary and recovery belong to a flow, independent of tabs.
- Screens are previewable and reusable with fake dependencies; they import no UIKit and no DI.
- Coordinators are testable with a spy.
- **Costs, stated plainly:**
  - More code than `NavigationStack` for a new iOS 17 app. This is a deliberate trade for ownership and for demonstrating the hybrid.
  - SwiftUI navigation conveniences are off limits in features (`.sheet`, `.toolbar`, `.navigationTitle`, `NavigationLink`). A lint rule has to hold that line.
  - Bar items are described as values, so highly dynamic toolbars need `ScreenChrome` to grow.
  - Views are untested, so logic must stay out of them.

## Alternatives

- **Stay all-SwiftUI.** Least code; keeps the tab-coupled flows and split sheet ownership; doesn't serve the project's purpose.
- **View model per screen.** Adds a type that holds state `@State` already holds and forwards calls `Routes` already forwards. No test worth having is lost without it, because the logic is in use cases and policies.
- **Routing protocol + router per feature.** Needs a weak presenter assigned after construction and still leaves the question of who pushes. Closures captured by the coordinator answer it with less.
- **Hosting-controller subclass per screen.** They differ only in title and bar items, which is data.
