# ADR 0008: A view model for every screen, built by factories

- **Status:** Accepted
- **Date:** 2026-11-18
- **Task:** F12-T1
- **Amends:** ADR 0001 ("no view models"), ADR 0007 (what a UIKit screen holds)

## Context

ADR 0001 rejected view models: a SwiftUI screen's `@State` already held the state, and `Routes` already forwarded the intents, so a view model would only have forwarded. ADR 0007 then made every screen a UIKit controller. That moved state, loading, which-alert-is-due decisions and route calls into the controllers (`SettingsViewController`, `RecordingPrestartViewController`, `RecordMelodyViewController`, …). That logic could then only be tested through UIKit, and each controller had two jobs: deciding and drawing. ADR 0001's reason no longer held. The owner asked for view models, and for factories to build them.

## Decision

- **Every screen has a view model.** It is a `@MainActor @Observable final class …ViewModel` in the feature module. It holds:
  - the screen's state: one `State` enum, plus what is being edited
  - its intents: plain methods, or `async` ones for work
  - its routes
  - which alert is due, as an `Alert` enum value

  It imports only Foundation, Observation, `SleepDomain` and `SleepCore`. `check-layering.py` enforces this by file name, so no UIKit, no SwiftUI, no ScreenKit, and no `Strings`.
- **The controller draws.** It redraws from the view model with `renderTracking`; forwards taps to it; runs its `async` work in tasks the controller owns (started on `viewIsAppearing`, cancelled on `viewDidDisappear`); and turns its `Alert` value into a `UIAlertController` with the text from `Strings` (`presentAlert(_:make:)`). It never calls a route.
- **No exceptions, checked.** A screen that only shows values (Learn, Briefing, the stages sheet, the events sheet) has one too: it holds what the screen shows and is the only caller of its routes, so a controller never holds data or routes. `check-layering.py` fails any feature class that subclasses `ScreenController` without a `let viewModel`. The owner chose this over the first version of this ADR, which left those four screens without one.
- **The composers become factories.** One per flow in AppShell (`HistoryScreenFactory`, `SessionDetailFactory`, `StatisticsFactory`, `SettingsFactory`, `RecordingFactory`, `OnboardingFactory`, `LearnFactory`, `BriefingFactory`; the briefing sheet was built in `AppCoordinator`). Each builds `Dependencies`, then the view model, then the controller. They stay the only screen code that resolves from the container. There are no per-screen factory types.
- **The existing state owners fit the shape:**
  - `ClipPlaybackModel` is renamed `PlayerViewModel`.
  - `LiveRecordingModel` stays the live night, and `BedsideClockViewModel` decides over it.
- Types the shared content owns (`TrendsRange`, `MelodyRecordingState`, `OnboardingPermission`) stay out of view models. A view model has its own value, and the controller maps it, or keeps a pure view selection (Trends' range) itself.

## Consequences

- **The screens' decisions are tested without UIKit.** View-model tests cover:
  - History: deleting a day
  - Session Detail: load, error, retry, share only with a clip
  - Onboarding: permissions and paging
  - Prestart: microphone, charging, start anyway
  - Countdown, summary, melody recording and picker
  - Settings: ordered writes, a lower limit asks, Health only when allowed

  These tests found a fake that disagreed with its adapter (`FakeMelodyRecorder` lost the take at the limit). The fake is fixed.
- **One more type per screen**: 19 view models for 21 screens (Trends, Calendar and Last 7 Nights share one). It's a deliberate cost: each has one job, deciding. Four of them (Learn, Briefing, the two sheets) are thin: they hold values and pass taps on.
- Flow tests reach routes through `controller.viewModel.routes`, so a view model's `routes` and `dependencies` are internal, read-only.
- Bindings into shared content are built in the controller from view-model values. A value a binding reads lazily is read during rendering, so a change redraws (render tracking only sees what was read).
- `Strings` stay in views and controllers, so a view model's alert is a case, not text.
- **No `@ObservationIgnored`.** `@Observable` tracks only stored `var`s, so `let`s (dependencies, routes, ports) are never tracked; a private `var` a render doesn't read (a pending task, a guard flag) causes no redraws. The cost is one rule: a controller's render reads only what it draws.

## Alternatives

- **Keep the logic in the controllers.** One type fewer per screen, but decisions stay testable only through UIKit. Rejected.
- **View models only where there is state or logic.** Four fewer types, but two shapes of screen, and controllers that hold data and call routes. The first version of this ADR chose it; the owner preferred one shape, checked.
- **A factory type per screen.** The same wiring in more types. Rejected: the flow's factory already has one job.
