# AGENTS.md

SleepGuardUIKitWay: SleepGuard rebuilt as UIKit screens hosting the shared SwiftUI content on a hexagonal core, shipped as white-label apps. `CLAUDE.md` is a copy of this file; keep them in sync (this file wins).

## Principles

Don't assume. Don't hide confusion. Surface trade-offs.

- State assumptions before implementing. If uncertain, ask.
- If several interpretations exist, present them; don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- Minimum code that solves the problem. No speculative features, no abstraction for single-use code, no configurability nobody asked for.
- Touch only what the task needs. Match existing style. Mention unrelated dead code; don't delete it.
- **Every architectural type must have one job you can state in a sentence.** This is a showcase of judgment, not of pattern count. If a type exists only because a familiar template has it, remove it.

## Architecture in one page

```
Brand app targets (SleepGuard | SleepGuardLite | Nocturne)
        │
     AppShell           UIKit lifecycle, coordinators, factories, Factory container
        │
  ┌─────┼─────────────┬──────────────┐
Features (UIKit)    ScreenKit      Adapters (SleepPersistence, SleepAudio, SleepHealth)
  │   └─ SleepGuardContentKit, SleepGuardDesignKit, SleepStrings (shared repo)   │
  └──────────► SleepDomain ◄──────────────────────────────────┘
                   └─ SleepCore (shared repo: Night entities, night rules, score, detection)
```

**The dependency rule:** everything points at `SleepDomain`. Nothing in `SleepDomain` knows about UI, persistence, DI, or brands.

| Module | May import | Never imports |
|---|---|---|
| `SleepDomain` | Foundation, `SleepCore` | everything else |
| Adapters | `SleepDomain`, `SleepCore`, the one Apple framework they wrap | SwiftUI, UIKit (except where the framework requires it), Factory, features |
| Features | `SleepDomain`, `SleepCore`, `SleepGuardContentKit`, `SleepGuardDesignKit` (which re-exports `SleepStrings`), `ScreenKit`, UIKit, SwiftUI (to host the shared content) | Factory, adapters, other features |
| A feature's `…ViewModel.swift` | Foundation, Observation, `SleepDomain`, `SleepCore` | UIKit, SwiftUI, `ScreenKit`, the kits (so no `Strings`) |
| `ScreenKit` | UIKit, SwiftUI, `SleepGuardDesignKit` | domain, features, Factory |
| `AppShell` | everything except `SleepHealth` | — |
| Brand targets | `AppShell`, the adapters that brand links | — |

Enforced by package manifests, **but only when a package builds on its own**: inside the app workspace Xcode lets any module it has already built be imported, declared or not (verified in F1-T3). So `scripts/run-tests.sh` builds every package standalone, and `scripts/check-layering.py` checks every module's imports against this table (`ALLOWED_IMPORTS`; a new module must be added there). Full notes: `docs/architecture/modules.md`.

## Domain

- **Entities and values** are `Sendable` structs. **Policies** are pure functions or structs (no ports, no clock unless passed in). **Ports** are `Sendable` protocols with `async` methods, named for their role (`SessionRepository`, `SleepStagePort`).
- **A use case exists only when it applies a policy or coordinates two or more ports** (`CommitSession`, `DeleteSession`, `LoadSessionDetail`). For a plain read, the screen's `Dependencies` holds the port. Never write a use case whose body is one forwarded call.
- A use case is a `Sendable` struct with one `callAsFunction`. Collaborators come through `init`. A use case never calls another use case.
- **The night itself is shared.** Entities (`Night`, `NightEvent`, `NightEpisode`, `NightSummary`) and the rules over them (episodes, snoring duration, stage stats, score inputs, score, summary), plus the score formula and detection, live in `SleepCore` in the shared repo, used by SleepGuard too. `SleepDomain` holds what is specific to this app's architecture: ports, use cases (and their output types such as `SessionDetail`), and fakes. A change to how a night is computed goes into `SleepCore`, never here.
- **No brand, no feature flag, no localized text in the domain.** If a rule differs per brand, the brand supplies a value or a policy; the domain never asks which brand it is.

## Adapters

- One adapter module per framework: `SleepPersistence` (SwiftData, files, UserDefaults), `SleepAudio` (AVFoundation, SoundAnalysis, Accelerate; the shared `SleepMelodies` sound files), `SleepHealth` (HealthKit).
- Adapter types and mappers are `internal`. A module exposes a small public factory surface and nothing else.
- Framework types never cross the port. Map to domain values inside the adapter.
- **SwiftData lives behind a `@ModelActor`.** `@Model` records never leave that actor. They are persistence records, not domain objects: no business logic on them.
- A brand that lacks a capability passes `nil` for its port in `BrandConfiguration` (ADR 0006): `health` is `SleepHealth.makeHealthAccess()` or `nil`. `SleepHealth` is linked only by brands that use it.

## Screens (UIKit, hosting shared SwiftUI content)

- **A screen is a UIKit view controller (ADR 0007).** It subclasses `ScreenController` from `ScreenKit` and owns the screen's structure (a collection view, a page view controller, or one hosted piece). The shared SwiftUI content draws inside it, through `UIHostingConfiguration` cells (`hosted { … }`), a hosted child (`host(_:)`), or `render(_:)`, which hosts once and redraws in place.
- **Every screen has a view model (ADR 0008; checked).** `@MainActor @Observable final class …ViewModel` in the feature: one `State` enum (`.loading`, `.loaded`, `.error`, plus `.empty` when the screen has one) and whatever is being edited; intents as methods (`async` for work); its `Routes`; which alert is due as an `Alert` enum value. No UI imports (checked), no `Strings`, no `@ObservationIgnored` (`let`s aren't tracked; a render reads only what it draws). A screen that only shows values still has one: it holds the values and the routes, so a controller never does.
- **The controller draws and forwards.** It redraws with `renderTracking { … }`, shows one state child at a time (`show(_:)`), forwards taps to the view model, runs its `async` work in tasks it owns, and turns its `Alert` into a `UIAlertController` (`presentAlert(_:make:)`, text from `Strings`). It never calls a route itself.
- An `@Observable` state owner over an imperative resource (the player, the live night) is a view model too (`PlayerViewModel`), or sits under one (`BedsideClockViewModel` over `LiveRecordingModel`).
- Each screen's public surface:
  ```swift
  public struct HistoryDependencies: Sendable { … }   // ports and use cases, plus plain values (flags, limits)
  public struct HistoryRoutes { … }                   // @MainActor closures: what the user asked for
  public final class HistoryViewModel { public init(dependencies:routes:) }
  public final class HistoryViewController: ScreenController { public init(viewModel:theme:chrome:) }
  ```
- **Three layers of view code (ADR 0005, narrowed by ADR 0007).** Components live in the shared `SleepGuardDesignKit`. A screen's content (its loaded layout, and state views that only draw) lives in the shared `SleepGuardContentKit`, used by SleepGuard too. The screen stays here: its view model (state, loading, `Routes`, which alert) and its UIKit controller (alerts, and, for a list or a pager, the container (sections, swipe actions, paging), whose cells and pages are shared views). The test: if a view can be rendered from plain values alone, it is shared; if it needs a port, a use case, a route or an alert, it is a screen. Don't write a SwiftUI layout in a feature module: add it to the content kit (values and closures in; an app-only extra goes through an optional value or a `@ViewBuilder` slot, never a flag naming an app). Something only this app draws (a placeholder) is a UIKit view. New screens are built content-first.
- The controller starts the view model's loading in `viewIsAppearing`, in a `Task` it owns, and cancels it in `viewDidDisappear` (and in `deinit`). Guard so popping back doesn't refetch. Observe changing data with the port's `AsyncStream` inside the view model's `observe()`. The view model checks `Task.isCancelled` before setting an error.
- **Forbidden in features:** `NavigationStack`, `NavigationLink`, `.navigationDestination`, `.sheet`, `.fullScreenCover`, `.navigationTitle`, `.toolbar`, `@Query`, `@Environment(\.modelContext)`, `@Injected`, `UIApplication`, `UIDevice`, `UINavigationController`, `navigationController`, `pushViewController`, `Navigator`, and `present(` of anything but a `UIAlertController` (named `…alert`, `…Alert()` or `…confirmation(…)`).
- Limits: a controller, view model or view file ≤ 200 lines. Split a screen's list or pager into its own controller (`NightsListController`) and its pure item builder (`NightsListItems`, tested).
- Accessibility: icon-only buttons have an accessibility label; custom-drawn views get one element with a label and a value; decorative visuals are hidden.

## Composition and navigation (UIKit)

- **UIKit owns navigation. All of it.** Coordinators push, pop, present and dismiss. A screen never does.
- **One screen base:** `ScreenController` in `ScreenKit`. Do not subclass `UIHostingController` per screen. Title and bar items are a `ScreenChrome` value applied by `ScreenController`.
- **One factory shape:** a `@MainActor struct …Factory` per flow in `AppShell` with `func make(routes:) -> UIViewController`. It resolves from the container, builds `Dependencies`, then the view model, then the controller with the brand's theme and its `ScreenChrome` (ADR 0008). No business logic, no navigation, no per-screen factory types.
- **Factories are the only screen code that resolves from the Factory container** (besides `AppShell.bootstrap`).
- Coordinators talk to UIKit through the `Navigator` protocol, so tests use `NavigatorSpy`.
- Screen-level modals are UIKit sheets presented by a coordinator.
- Deep links parse to an `AppRoute` in the scene delegate and are handled by `AppCoordinator`.
- A coordinator owns the tasks it starts and cancels them when it goes away. Closures passed to screens capture the coordinator weakly.

Notes: `docs/architecture/composition.md`, `docs/architecture/navigation.md`.

## Dependency injection

- Modules below `AppShell` use plain initializer injection and never import Factory.
- `AppShell` owns the Factory `Container`. `Sendable` ports get nonisolated factories; main-actor objects get `@MainActor` factories.
- Every port has a fake in a `…TestSupport` product. Fakes are actors or `Sendable` structs, never `@unchecked Sendable`.

## Brands (white-label)

- Three real app targets generated by Tuist from `Brand.all` in `Tuist/ProjectDescriptionHelpers/Brand.swift`. That entry holds the build-time identity: target name, display name, bundle id, URL scheme (the app group derives from the bundle id).
- A brand's folder under `Apps/` holds `Brand.swift` (its `BrandComposition`, from F1-T7), an asset catalog (icon, `LaunchBackground`, `BrandAccent`) and entitlements. Nothing else is brand-specific.
- `BrandComposition` is a protocol. A brand that forgets a binding does not compile. No `fatalError("register me")` placeholders.
- **No `if brand == …` anywhere.** Brand differences reach code only through `BrandConfiguration` (theme, tabs, `health`, `appStoreID`; every brand states each, ADR 0006), read in two places only: coordinators (which tabs and flows exist) and factories (which pass plain values into `Dependencies`).
- Theme is a `Theme` value from `SleepGuardDesignKit`, supplied by the brand and injected into the SwiftUI environment of everything `ScreenController` hosts. Views read `@Environment(\.theme)`; UIKit code uses `UIColor(theme.palette…)` and `theme.typography.uiFont(size:weight:)`. Never hard-code a colour, radius or font that a token covers.
- Adding a brand must stay "one list entry and one folder". If a change makes it more, stop and rethink.

Notes: `docs/architecture/brands.md`.

## Design

- Screen designs come from SleepGuard's design file, `../SleepGuard/designs/SleepGuard.pen` (read it with the Pencil MCP tools, never as a file). Match structure, spacing and typography.
- Colours come from the brand's `Theme`, not from the design file's hex values: the design shows the SleepGuard brand.

## Localization

- Every user-facing string goes through `Strings.x`. The catalog is `SleepStrings` in the shared repo; `SleepGuardDesignKit` re-exports it (`@_exported import SleepStrings`), so a file that imports the design kit can use `Strings` without a second import. This matches SleepGuard, where `DesignSystem` does the same. Never a literal in `Text`, `Button`, a `ScreenChrome` title, or an alert. Never `String(localized:)` directly.
- Strings are added in `../SleepGuardShared` (see its README). A new string affects SleepGuard too.
- Text that names the app takes the brand name as an argument from `BrandConfiguration`.
- Only views, controllers, factories (for chrome titles) and content engines whose output is text may use `Strings`. A content engine that isn't a view imports `SleepStrings` directly rather than the design kit.

## Concurrency

- Swift 6 language mode in every target, including the three apps. No `@unchecked Sendable`, `nonisolated(unsafe)`, `@preconcurrency` or unchecked lock state (`uncheckedState`, `withLockUnchecked`), test code included. The one exception is the lock in the realtime audio tap (`SleepAudio/Capture/CaptureProcessor.swift`): the tap's thread can't await, and the lock guards AVFoundation objects that aren't `Sendable`. It is the only entry in `ESCAPE_HATCH_ALLOWLIST`.
- `SleepDomain` and adapters: no default isolation. Features, `ScreenKit`, `AppShell`: `.defaultIsolation(MainActor.self)`. A diffable identifier type in a feature is `nonisolated`.
- `async/await` only. No Combine, no GCD, no completion handlers, no NotificationCenter as an event bus.
- No fire-and-forget `Task` in a load path. Tests `await`; they never poll or sleep.
- Check `Task.isCancelled` before setting an error state.
- Live detection is one ordered stream into `DetectionEngine` (from `SleepCore`). Never change detection state from a side path. `RecordingSession` (SleepDomain, an actor) is the one sender: it classifies each capture sample, sends it, and performs the engine's outputs in order (clips through `AudioCapturePort`, events into the `RecordingDraft` value). Clip compression runs beside the engine, never inside a batch.

Notes: `docs/architecture/concurrency.md`.

## Testing

- Swift Testing only. `SleepDomain` tests run on macOS with `swift test`; everything else on the pinned simulator.
- What must have tests: policies, use cases, view models (with the fakes), mappers, adapters (against in-memory stores), coordinators (through `NavigatorSpy`), and brand bootstrap (every brand resolves every registration).
- Views and controllers are not unit-tested. Keep logic out of them (view models, item builders, rules in `SleepCore`) so that this is acceptable.

## Working style

- Enter plan mode for any non-trivial task (3+ steps or an architectural decision).
- If something goes sideways, stop and re-plan.
- Bug report: just fix it. Read logs, trace, resolve.
- Never mark a task complete without proving it works: build every brand scheme, run the tests, check the acceptance criteria.
- Write an ADR (`docs/adr/NNNN-slug.md`: context, decision, consequences with honest limits, alternatives) when a task changes a boundary, a rule in this file, or a trade-off a reviewer would question.
- Ask before every commit and before anything outward-facing (push, remote, PR). No AI attribution in commit messages.

## Response rules

- No filler. Start with the answer.
- Match length to complexity.
- Flag uncertainty about facts, libraries or tools before proceeding.
- Before any destructive action, list what is affected and wait for an explicit yes.

## Workflow and trackers

Full process: `docs/CODING_WORKFLOW.md`.

```
SESSION START   read docs/FeatureTracker.md → pick the highest-priority unblocked task
PER TASK        tracker → "In Progress" → build it → verify → tracker → "Done"
FEATURE DONE    write docs/features/f#-name.md, update docs/Roadmap.md
SESSION END     write a fragment in docs/sessions/ (see its README)
```

- `docs/FeatureTracker.md` and `docs/trackers/f#-name.md` are the source of truth. Update them after every task, before anything else.
- Templates: `docs/templates/`.

## Build and report

```bash
tuist generate --no-open                          # uses ../SleepGuardShared (local edits)
TUIST_SHARED_RELEASE=1 tuist generate --no-open   # uses the pinned release (what CI builds)
xcodebuild build -workspace SleepGuardUIKitWay.xcworkspace -scheme <SleepGuard|SleepGuardLite|Nocturne> \
  -destination 'platform=iOS Simulator,id=BD630AD5-5A05-4663-8F1B-A17283EBCBF5'
sh scripts/run-tests.sh [macos|packages|hosted]   # all lanes by default; per-test time limits
python3 scripts/check-layering.py                # imports per module, escape hatches, print, .shared, feature bans
python3 scripts/check-view-size.py               # 200 lines per view file, 100 per *Screen.swift
python3 scripts/check-hardcoded-strings.py       # user-facing literals, String(localized:)
swiftformat Packages Apps Project.swift Tuist --lint
sh scripts/bump-shared.sh <version>              # move to a new SleepGuardShared release
```

Tools are pinned in `mise.toml` (`mise install`). CI (`.github/workflows/ci.yml`) runs the checks, builds every brand and runs `run-tests.sh` on every pull request, against the pinned shared release.

After every task: all three schemes build with zero errors, tests pass, checks pass. A change that builds for one brand is not done.

At the end of every session, report: files changed (one line each), what was verified and what was not, follow-ups needing a decision, **suggested branch** (`feature/f#/t#-short-description`) and **suggested commit** (`F#-T# — Short description` plus bullets). Then write the session fragment.

## Architecture reference

| Doc | When to read |
|---|---|
| `docs/ARCHITECTURE_PLAN.md` | The approved proposal: analysis of SleepGuard, target architecture, roadmap, trade-offs |
| `docs/architecture/INDEX.md` | Orientation |
| `docs/architecture/modules.md` | Adding a module or a dependency |
| `docs/architecture/domain.md` | Entities, policies, ports, use cases |
| `docs/architecture/composition.md` | Hosting a SwiftUI screen in the shell |
| `docs/architecture/navigation.md` | Coordinators, routes, sheets, deep links |
| `docs/architecture/dependencies.md` | The container, registrations, fakes |
| `docs/architecture/brands.md` | Brand configuration, capabilities, theme, adding a brand |
| `docs/architecture/concurrency.md` | Isolation, actors, tasks |
| `docs/architecture/testing.md` | What to test and how |
| `docs/architecture/feature-template.md` | Building a new feature end to end |
| `docs/architecture/rules.md` | Checklist for auditing a change |
