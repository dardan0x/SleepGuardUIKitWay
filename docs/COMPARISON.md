# Same feature, two architectures

SleepGuard and this app are the same product. SleepGuard is SwiftUI with the MV pattern: views load their own data from SwiftData and navigate with `NavigationStack`. This app is UIKit screens and coordinators on a hexagonal core. Since F10 both apps compute with the same shared rules and draw with the same shared views; since F11 (ADR 0007) this app's screens are UIKit controllers that host those views as cells and pages, so for History, the night detail and onboarding the container layout is UIKit here and SwiftUI there.

This compares one feature, **a night's detail**: open a night, load it, read its sleep stages from Apple Health if it has none, show the shared layout, filter events, play, share, delete. Line counts are from both repos on 2026-11-17.

## Where each concern lives

| Concern | SleepGuard (SwiftUI, MV) | This app (UIKit shell, hexagonal) |
|---|---|---|
| Opening the screen | `RouterPath.navigate(to: .sessionDetail(id:))`; `AppRegistry` maps it to a view | A route closure → `HistoryFlow` → `NightDetailNavigation.show(_:)` → `SessionDetailFactory.make(...)` → `Navigator.push` |
| State and decisions | `SessionDetailModel` (`@Observable`) plus `@State` in the view | `SessionDetailViewModel` (ADR 0008): state, filter, which route a tap means; no UI imports, tested with fakes. The UIKit controller only draws it |
| Loading the night | `SessionDetailModel.load(modelContext:)`: a SwiftData fetch in the state owner | `LoadSessionDetailUseCase` (use case) over the `SessionRepositoryPort` port; a SwiftData adapter behind it |
| Sleep stages from Health | The same `load`: `healthKitSync.fetchSleepStages(for:)`, written to the `@Model` | The same use case asks the `SleepStageSourcePort`; the container hands it the brand's `HealthAccessPort`, or `NoSleepStages` in Lite |
| Saving the new score | `session.refreshCachedScore(...)`, then `modelContext.save()` | The use case saves the night with its new summary through the port |
| The layout | `NightDetailContent` (shared) | `NightDetailContent` (shared) |
| Title and bar buttons | `.toolbar` in the view | `ScreenChrome` from the factory; the screen can't set them (checked) |
| Sheets (events, player, stages, share) | `.sheet` in the view, or `UIActivityViewController` on the key window | Routes out of the screen; `NightDetailNavigation` presents through the `Navigator` |
| Delete | The model deletes from the context at once; the view dismisses (no confirmation) | A route asks the navigation object, which confirms (alert), runs `DeleteSessionUseCase`, then pops |
| Brand differences | Remote Config flags read in the view (`appConfig.isEnabled(.pdfReport)`) | Read in the container and factories only; the screen gets plain values |

## Size

| | SleepGuard | This app |
|---|---|---|
| Screen and its state | `SessionDetailView` 127 (about 70 of them a dead mini-player kept "in case"), `SessionDetailLoadedView` 148, `SessionDetailModel` 141 | `SessionDetailViewModel` 76, `SessionDetailViewController` 86, the UIKit layout (`NightDetailController` 165, `NightDetailItems` 59, `FilterCell` 44), `SessionDetailRoutes` 37, UIKit state views 111 |
| Loading and rules | Inside the model | `LoadSessionDetailUseCase` 53, ports 66 (`SessionRepositoryPort`, `SleepStageSourcePort`) |
| Navigation and sharing | `SessionShareCoordinator` 90; the routes are one enum case | `NightDetailNavigation` 135, the detail's factory (most of `HistoryFactories` 89), `ShareSheet` 8 |
| **Total** | **about 500 lines, 4 files** | **about 900 lines, 14 files** |

Until F10 the totals were about the same (about 480 lines, 9 files here). Since F11 and F12 this app's night detail is almost twice SleepGuard's: the UIKit layout, the UIKit state views and the view model are the price of a UIKit screen whose decisions are tested without UI. SleepGuard keeps a feature together in a few files; this app spreads it over more, each with one job.

## Tests for this feature

| | SleepGuard | This app |
|---|---|---|
| Loading, stages, score refresh, delete | `SessionDetailModelTests`: 10, on an in-memory SwiftData store, on the simulator | `LoadSessionDetailTests` and `DeleteSessionTests`: 9, on fakes, on macOS in milliseconds |
| Navigation: push, sheets, delete confirmation, share | None (it's in the view) | `HistoryFlowTests`: 11, over a navigator spy, no UI |
| In the running app | None | `SessionsTabInAppTests` in every brand's app |

## What this app's shape buys

- **Navigation is testable without a UI.** "Delete asks first, then pops" and "the stages info opens a sheet" are plain tests here. In SleepGuard they live in `.sheet` and `.alert` modifiers and are checked only by hand.
- **The rules run on macOS, in milliseconds.** `SleepDomain` imports no Apple UI or storage framework, so its use cases run under `swift test` against fakes.
- **A brand difference is a value in one place.** Lite doesn't read sleep stages because the container gives it `NoSleepStages`; the screen and the use case don't know. Adding Dawn (`docs/ADDING_A_BRAND.md`) touched one folder and one list entry. In SleepGuard, a variant is a runtime flag read wherever it matters.
- **Storage is behind a port.** No screen sees a SwiftData model, so the faulting crashes that made SleepGuard cache scores on its `@Model` (and refresh them defensively on every open) don't reach the UI here. A screen gets values.
- **Boundaries are enforced, not remembered.** `check-layering.py` fails a feature that imports another feature, presents a sheet, or touches storage. Each package also builds in isolation, so an undeclared import fails CI.

## What it costs

- **Indirection.** Opening one screen goes through a route, a flow, a navigation object, a factory, the container and the hosting controller. Following a tap means reading five files; in SleepGuard it's one enum case and one view.
- **Ceremony per screen.** Every screen has a `Dependencies` and a `Routes` struct, a factory function and a flow method. Each new action on the night detail (share a clip, export a report) touched the routes, the screen, the navigation object and a test, where SleepGuard added a button and a call.
- **Workarounds the boundaries force.** The shell may not import the shared content kit, so the PDF report is drawn by `NightReportExport` inside a feature, and the stages sheet needs its own `SleepStagesInfoScreen` to host shared content. Neither exists in SleepGuard.
- **More to keep in step.** Twelve ports, each with an adapter and a fake. A capability added to `BrandConfiguration` must be stated by every brand (intended, but it is work).
- **Slower tests overall.** The rules are fast, but the full suite builds every package on its own (separate derived data each), then every brand's app. That catches real mistakes, and it costs build time SleepGuard doesn't spend: its packages build once, together.
- **Things that bit during the build.** Factory singletons are shared between test containers, so tests read stores they registered rather than resolve them again. Composition code hit Swift type-checker crashes twice and had to be spelled out. Neither came up in SleepGuard.

## Where SleepGuard's shape is simply better

- **Small features.** The Learn tab is a web page. In SleepGuard it's one view; here it's a feature module, a screen, a flow, a brand value, a test and a layering entry. That's fine as a showcase, but heavy for a web view.
- **One team, one app.** With one brand and a few people, the boundaries protect against mistakes that a code review catches anyway, and the indirection is paid on every change.
- **Reading the code.** A new developer finds the night detail in one place in SleepGuard. Here they need `ARCHITECTURE.md` first.

## Where SleepGuard pays later

- **Rules inside views and models.** Before F10 and F26, SleepGuard's briefing picked its content at random inside an engine that imported the design system. Its report drew hard-coded English. Its profile prompt re-rolled its chance on every redraw. Moving each to the shared repo exposed the problem, and each was fixed there for both apps. The MV shape didn't prevent them.
- **Dead code survives.** The night detail still carries a commented-out mini player and its helpers "kept verbatim". With nothing pulling code apart, nothing forces a decision.
- **Storage reaches the screen.** Views and models hold SwiftData objects, so a schema concern (faulting, cached fields, migration rules) is every screen's concern.

## The verdict

For one app, one brand and a small team, SleepGuard's shape is cheaper: fewer files, fewer hops, and features ship in fewer lines. This app's shape costs about the same number of lines per feature, spread over twice as many files. It earns that back when the app is several apps, the team is larger than the codebase is old, or the rules must be trusted without running the UI. Both apps now share the parts that matter most (the rules, the strings and the layouts), and that, more than either architecture, is what keeps them consistent.
