# ADR 0007: UIKit screens hosting the shared content

- **Status:** Accepted
- **Date:** 2026-11-18
- **Task:** F11-T1
- **Amends:** ADR 0001 (SwiftUI screens), ADR 0005 (what stays per app)

## Context

After F10 every screen in this app was a SwiftUI view inside one `HostingScreen`. UIKit owned navigation and nothing else, so for a reader the app was "SwiftUI with a UIKit bridge", not a UIKit app. The owner asked for real UIKit UI mixed with SwiftUI. They first asked for History, Onboarding and Session Detail, then for every view this app writes itself. The constraint: keep the architecture, keep sharing layouts with SleepGuard (ADR 0005), and don't touch SleepGuard's behaviour.

Three depths were on the table: thin UIKit wrappers around whole SwiftUI screens; UIKit containers with shared SwiftUI pieces as their cells and pages; or rewriting the views in UIKit. The owner chose containers.

## Decision

- **Every screen is a UIKit view controller.** It subclasses `ScreenController` (ScreenKit), which applies the `ScreenChrome`, paints the brand background, puts the theme into whatever it hosts, and shows one state child at a time (`show(_:)`). The controller owns the screen's state as plain properties, its loading tasks (started on `viewIsAppearing`, cancelled on `viewDidDisappear`) and its alerts (`UIAlertController`). There are still no view models.
- **UIKit owns structure where there is structure:**
  - History is a `UICollectionView` list, with diffable sections per month, swipe to delete, and expansion owned by the list.
  - Onboarding is a `UIPageViewController`, with UIKit Skip and Back buttons.
  - Session Detail is a compositional collection view, with a native `UISegmentedControl` filter and UIKit text for the events title and "Show all".
  - The dashboard is a list plus a pinned button.
  - Trends, Calendar, Last 7 Nights, the player and the events sheet sit in `ContentListController`, a self-sizing UIKit list.
- **Shared SwiftUI draws the pieces.** Cells use `UIHostingConfiguration` (`hosted { … }`); whole-screen content is hosted once and redrawn in place (`render(_:)`). Screens with an `@Observable` state owner (player, bedside clock) redraw through `renderTracking`, which re-runs on change.
- **What only this app draws is UIKit.** The night detail's loading and error states are `UIView`s.
- **The shared repo gains public pieces, not behaviour:**
  - `NightDayCard` (expansion now owned by its list)
  - `NightMonthHeader`
  - `OnboardingPageView` and `OnboardingDots`
  - `NightDetailHeader`
  - `NightDetailContent.visibleRows`

  SleepGuard's screens are rebuilt from the same pieces and render the same.
- **Navigation is unchanged.** Screens call `Routes`; coordinators push and present through `Navigator`. A feature may import UIKit and ScreenKit now. The layering check bans `UINavigationController`, `navigationController`, `pushViewController`, `Navigator`, and presenting anything but an alert.
- `HostingScreen` is removed: nothing hosts a whole SwiftUI screen any more.

## Consequences

- The app reads as a UIKit app: lists, pagers, segmented controls, alerts, child containment and diffable data sources, with SwiftUI where the two apps share drawing.
- **ADR 0005 is narrowed.** Leaf visuals stay shared. But the container layout of History, Session Detail and Onboarding is now written here in UIKit: section order, spacing, swipe actions, paging, the filter control. A layout change to those three screens in SleepGuard has to be mirrored here by hand, and they can drift. The other screens still host one shared layout each, so they can't drift.
- **More code per screen.** A controller with its lifecycle replaces `.task` and `@State`. Item builders (`NightsListItems`, `NightDetailItems`) are pure and tested; drawing is still not unit-tested.
- Features still import SwiftUI, only to host shared content and to build `Binding`s into it. A SwiftUI layout in a feature module is still a review failure.
- `UIHostingConfiguration` cells resize themselves; expanding a day reconfigures its cell. This was checked on the simulator for the list and the detail, not on a device.
- One honest limit: the onboarding pager redraws every page's hosted view on each state change (six pages). It's cheap, but it's not minimal.

## Alternatives

- **Thin UIKit wrappers** (a controller embedding the whole shared SwiftUI screen). Least work, no shared release. Rejected: UIKit would still be only a frame.
- **Pure UIKit views.** Rejected: it breaks ADR 0005, and every layout fix would have to be made twice, in two UI frameworks.
- **Keep `HostingScreen` for the simple screens.** Rejected at the owner's request ("everything that can be UIKit"). It would also leave two screen shapes to learn.
