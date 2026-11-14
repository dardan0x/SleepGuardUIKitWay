# CLAUDE.md

SleepGuardUIKitWay: SleepGuard rebuilt as a UIKit shell hosting SwiftUI screens on a hexagonal core, shipped as three white-label apps. This file is a copy of `AGENTS.md`; keep them in sync (`AGENTS.md` wins).

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
     AppShell           UIKit lifecycle, coordinators, composers, Factory container
        │
  ┌─────┼─────────────┬──────────────┐
Features (SwiftUI)  ScreenKit      Adapters (SleepPersistence, SleepAudio, SleepHealth)
  │   └─ SleepGuardDesignKit, SleepStrings (shared repo)      │
  └──────────► SleepDomain ◄──────────────────────────────────┘
                   └─ SleepCore (shared repo)
```

**The dependency rule:** everything points at `SleepDomain`. Nothing in `SleepDomain` knows about UI, persistence, DI, or brands.

| Module | May import | Never imports |
|---|---|---|
| `SleepDomain` | Foundation, `SleepCore` | everything else |
| Adapters | `SleepDomain`, `SleepCore`, the one Apple framework they wrap | SwiftUI, UIKit (except where the framework requires it), Factory, features |
| Features | `SleepDomain`, `SleepCore`, `SleepGuardDesignKit` (which re-exports `SleepStrings`), SwiftUI | UIKit, Factory, adapters, other features |
| `ScreenKit` | UIKit, SwiftUI, `SleepGuardDesignKit` | domain, features, Factory |
| `AppShell` | everything except `SleepHealth` | — |
| Brand targets | `AppShell`, the adapters that brand links | — |

Enforced by package manifests first, then `scripts/check-layering.py` (added in F1-T8). Full notes: `docs/architecture/modules.md`.

## Domain

- **Entities and values** are `Sendable` structs. **Policies** are pure functions or structs (no ports, no clock unless passed in). **Ports** are `Sendable` protocols with `async` methods, named for their role (`SessionRepository`, `SleepStagePort`).
- **A use case exists only when it applies a policy or coordinates two or more ports** (`CommitSession`, `DeleteSession`, `LoadSessionDetail`). For a plain read, the screen's `Dependencies` holds the port. Never write a use case whose body is one forwarded call.
- A use case is a `Sendable` struct with one `callAsFunction`. Collaborators come through `init`. A use case never calls another use case.
- Score, detection and the stored value types come from `SleepCore` in the shared repo. Don't re-implement them here.
- **No brand, no feature flag, no localized text in the domain.** If a rule differs per brand, the brand supplies a value or a policy; the domain never asks which brand it is.

## Adapters

- One adapter module per framework: `SleepPersistence` (SwiftData, files, UserDefaults), `SleepAudio` (AVFoundation, SoundAnalysis, Accelerate), `SleepHealth` (HealthKit).
- Adapter types and mappers are `internal`. A module exposes a small public factory surface and nothing else.
- Framework types never cross the port. Map to domain values inside the adapter.
- **SwiftData lives behind a `@ModelActor`.** `@Model` records never leave that actor. They are persistence records, not domain objects: no business logic on them.
- A brand that lacks a capability binds a `NoOp` adapter. `SleepHealth` is linked only by brands that use it.

## Screens (SwiftUI, MV style)

- **No view models.** A screen is a SwiftUI view with `@State` and a `ViewState` enum (`.loading`, `.loaded`, `.error`, plus `.empty` when the screen has one). No boolean soup.
- An `@Observable` state owner is allowed only when state owns an imperative resource (audio playback, timers). It is built by the composer and passed in. Never one per screen by reflex.
- Each screen's public surface is three things:
  ```swift
  public struct HistoryDependencies: Sendable { … }   // ports and use cases, plus plain values (flags, limits)
  public struct HistoryRoutes { … }                   // @MainActor closures: what the user asked for
  public struct HistoryScreen: View { public init(dependencies:routes:) }
  ```
- Only the screen (container) view takes `Dependencies` and `Routes`. Child views are presentational: data in, closures out.
- Load in `.task`. Guard so popping back doesn't refetch. Observe changing data with the port's `AsyncStream` inside `.task`.
- **Forbidden in features:** `NavigationStack`, `NavigationLink`, `.navigationDestination`, `.sheet`, `.fullScreenCover`, `.navigationTitle`, `.toolbar`, `@Query`, `@Environment(\.modelContext)`, `@Injected`, `UIApplication`, `UIDevice`. Allowed: `.alert`, `.confirmationDialog`.
- Limits: a view file ≤ 200 lines; a screen container ≤ 100 lines; state views (`…LoadedView`, `…EmptyView`, `…ErrorView`) in their own files. Prefer a dedicated `View` struct over a computed `some View` for anything over ~20 lines or anything built per item.
- Accessibility: icon-only buttons use `Label(…).labelStyle(.iconOnly)`; custom-drawn views get one element with a label and a value; decorative visuals are hidden.

## Composition and navigation (UIKit)

- **UIKit owns navigation. All of it.** Coordinators push, pop, present and dismiss. A screen never does.
- **One hosting controller:** `HostingScreen<Content>` in `ScreenKit`. Do not subclass `UIHostingController` per screen. Title and bar items are a `ScreenChrome` value applied by `HostingScreen`.
- **One composer shape:** a `@MainActor struct …ScreenComposer` in `AppShell` with `func make(routes:) -> UIViewController`. It resolves from the container, builds `Dependencies`, builds the screen, wraps it in `HostingScreen`. No business logic, no navigation.
- **Composers are the only code that resolves from the Factory container** (besides `AppShell.bootstrap`).
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

- Three real app targets generated by Tuist from one list in `Tuist/ProjectDescriptionHelpers`.
- A brand is one folder under `Apps/`: `Brand.swift` (its `BrandComposition`), an asset catalog, an xcconfig, entitlements. Nothing else is brand-specific.
- `BrandComposition` is a protocol. A brand that forgets a binding does not compile. No `fatalError("register me")` placeholders.
- **No `if brand == …` anywhere.** `BrandConfiguration.capabilities` is read in two places only: coordinators (which tabs and flows exist) and composers (which pass plain values into `Dependencies`).
- Theme is a `Theme` value from `SleepGuardDesignKit`, supplied by the brand and injected into the SwiftUI environment by `HostingScreen`. Views read `@Environment(\.theme)`. Never hard-code a colour, radius or font that a token covers.
- Adding a brand must stay "one list entry and one folder". If a change makes it more, stop and rethink.

Notes: `docs/architecture/brands.md`.

## Design

- Screen designs come from SleepGuard's design file, `../SleepGuard/designs/SleepGuard.pen` (read it with the Pencil MCP tools, never as a file). Match structure, spacing and typography.
- Colours come from the brand's `Theme`, not from the design file's hex values: the design shows the SleepGuard brand.

## Localization

- Every user-facing string goes through `Strings.x`. The catalog is `SleepStrings` in the shared repo; `SleepGuardDesignKit` re-exports it (`@_exported import SleepStrings`), so a file that imports the design kit can use `Strings` without a second import. This matches SleepGuard, where `DesignSystem` does the same. Never a literal in `Text`, `Button`, a `ScreenChrome` title, or an alert. Never `String(localized:)` directly.
- Strings are added in `../SleepGuardShared` (see its README). A new string affects SleepGuard too.
- Text that names the app takes the brand name as an argument from `BrandConfiguration`.
- Only views, composers (for chrome titles) and content engines whose output is text may use `Strings`. A content engine that isn't a view imports `SleepStrings` directly rather than the design kit.

## Concurrency

- Swift 6 language mode in every target, including the three apps. No `@unchecked Sendable`, `nonisolated(unsafe)` or `@preconcurrency`, test code included. The one documented exception is the lock in the realtime audio tap.
- `SleepDomain` and adapters: no default isolation. Features, `ScreenKit`, `AppShell`: `.defaultIsolation(MainActor.self)`.
- `async/await` only. No Combine, no GCD, no completion handlers, no NotificationCenter as an event bus.
- No fire-and-forget `Task` in a load path. Tests `await`; they never poll or sleep.
- Check `Task.isCancelled` before setting an error state.
- Live detection is one ordered stream into `DetectionEngine` (from `SleepCore`). Never change detection state from a side path.

Notes: `docs/architecture/concurrency.md`.

## Testing

- Swift Testing only. `SleepDomain` tests run on macOS with `swift test`; everything else on the pinned simulator.
- What must have tests: policies, use cases, mappers, adapters (against in-memory stores), coordinators (through `NavigatorSpy`), and brand bootstrap (every brand resolves every registration).
- Views are not unit-tested. Keep logic out of them so that this is acceptable.

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
tuist generate --no-open
xcodebuild build -workspace SleepGuardUIKitWay.xcworkspace -scheme <SleepGuard|SleepGuardLite|Nocturne> \
  -destination 'platform=iOS Simulator,id=BD630AD5-5A05-4663-8F1B-A17283EBCBF5'
sh scripts/run-tests.sh            # added in F1-T8
python3 scripts/check-layering.py  # added in F1-T8
```

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
