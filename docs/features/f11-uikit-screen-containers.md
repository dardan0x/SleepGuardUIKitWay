# F11 — UIKit screen containers

Every screen in this app is a UIKit view controller. UIKit owns where things go and how they move: lists, pagers, the filter control, state changes, loading, alerts. The shared SwiftUI views from SleepGuardShared draw what is inside. Navigation is unchanged: screens report intents through `Routes`, and coordinators act through `Navigator`. Decided with the owner on 2026-11-18 (ADR 0007).

## The shape of a screen

| Piece | Where | Job |
|---|---|---|
| `ScreenController` | ScreenKit | Every screen's base: background, `ScreenChrome`, the theme in what it hosts, one state child at a time, large titles following the child's scroll view |
| `ContentListController` | ScreenKit | A self-sizing UIKit list of rows, each a hosted shared view or UIKit content |
| `hosted { … }` / `host(_:)` / `render(_:)` | ScreenKit | A shared view as a cell / as a child or page / as the whole content, redrawn in place |
| `renderTracking { … }` | ScreenKit | Redraw when an `@Observable` state owner changes (player, bedside clock) |
| `Typography.uiFont(size:weight:)` | ScreenKit | The theme's font for UIKit text |
| `…ViewController` | Features | State, loading task, alerts, routes |
| `…Items` | Features | A list's or detail's sections and items, pure and tested |

## Screens

| Screen | UIKit structure | Shared drawing |
|---|---|---|
| History | `NightsListController`: diffable list, month headers, swipe to delete, expansion owned by the list | `NightMonthHeader`, `NightDayCard`, empty and loading content |
| Session Detail | `NightDetailController`: compositional layout, `UISegmentedControl` filter (`FilterCell`), UIKit events title and "Show all"; UIKit loading and error views | `NightDetailHeader`, `SleepStagesCard`, `NightTimeline`, banners, `EventRow` |
| Onboarding | `UIPageViewController`, UIKit Skip and Back (`OnboardingLayout`) | `OnboardingPageView`, `OnboardingDots` |
| Dashboard | A list plus Start Recording pinned below (`DashboardLayout`); reads the latest night's stages | `ProfilePromptCard`, `StatisticsDashboardContent`, `SleepStagesCard`, `StartRecordingButton` |
| Trends, Calendar, Last 7 Nights | `NightsScreenController` (live nights) and `ContentListController` | Their content views |
| Player, events sheet | `ContentListController` | `PlayerContent`, `NoAudioCard`, `EventsGridContent` |
| Recording (prestart, countdown, bedside clock, summary, melody, interrupter, picker), Settings, profile editor, Learn, Briefing, stages sheet | Hosted content redrawn in place; UIKit alerts; timers as owned tasks | Their content views |

## Files

| File | Purpose |
|---|---|
| `Packages/Presentation/Sources/ScreenKit/ScreenController.swift` | The screen base and `ThemedScreen` |
| `Packages/Presentation/Sources/ScreenKit/ContentListController.swift`, `ThemeFonts.swift` | The content list; UIKit fonts |
| `Packages/Features/Sources/HistoryFeature/*` | `HistoryViewController`, `NightsListController`, `NightsListItems` |
| `Packages/Features/Sources/SessionDetailFeature/*` | `SessionDetailViewController`, `NightDetailController`, `NightDetailItems`, `FilterCell`, UIKit state views, player and sheets |
| `Packages/Features/Sources/OnboardingFeature/*` | `OnboardingViewController`, `OnboardingLayout` |
| `Packages/Features/Sources/{Statistics,Recording,Settings,Learn,Briefing}Feature/*` | The other screens as controllers |
| `../SleepGuardShared/Sources/SleepGuardContentKit/{Nights,Onboarding}/*` | The pieces made public (0.28.0) |
| `scripts/check-layering.py`, `scripts/check-view-size.py` | The new feature bans; controllers ≤ 200 lines |
| `docs/adr/0007-uikit-screen-containers.md` | The decision |

## Edge cases

- Coming back to History re-subscribes and yields the current list at once, so no loading state flashes; expanded days that are still listed stay expanded.
- A night detail cancelled while loading (the screen popped or disappeared) loads again on the next appearance and never shows an error.
- The bedside clock shows the start-failed alert once, however often it redraws.
- A lower storage limit asks first, then saves before enforcing (the screen runs its writes in order).

## Limits

- History, the detail and onboarding lay out shared pieces in UIKit here. A layout change to them in SleepGuard has to be mirrored by hand.
- Onboarding on a fresh install, swipe to delete and the other brands were covered by tests, not by eye.
