# ADR 0009: One composition per brand; flows take what they use

- **Status:** Accepted
- **Date:** 2026-11-26
- **Task:** F13-T8 (architecture review Q47, Q48)
- **Amends:** ADR 0003 (how the brand reaches the shell), ADR 0006 (where capabilities are read)

## Context

The shell registered its services on Factory's `Container.shared`. The brand was one more registration, set by `AppShell.bootstrap(brand:)`, and its default was `preconditionFailure`: anything that resolved before bootstrap crashed at runtime. Every flow (`HistoryFlow`, `RecordingFlow`, …), `NightDetailNavigation` and `MainTabCoordinator` took the whole container and resolved what it needed inside its initializer, so a flow's dependencies were invisible in its signature (a service locator), and a flow could reach any service. If the store couldn't open even in memory, a `try!` crashed with no message. `BrandBootstrapTests` resolved 14 of 28 registrations, although it said "every registration".

## Decision

- `AppComposition(brand:)` is the composition root. It makes its own `Container()`, registers the brand before returning, and builds every flow and the tab bar. The app never uses `Container.shared` (the layering check now bans it outright).
- Flows, `NightDetailNavigation` and `MainTabCoordinator` take exactly what they use as initializer arguments: their screen factory, use cases, stores, plain values (the App Store id, the clips folder). `MainTabCoordinator` takes the theme, the tabs and a `makeFlow` closure.
- The screen factories remain composition code and still read the container; nothing below them does.
- `AppCoordinator(composition:)` reads typed accessors on the composition (`recoverInterruptedSession`, `storeOpening`, …), not the container.
- The container's registrations are `.cached` (once per container), not `.singleton`: Factory's singleton scope is one per process, so a second container (a test's) got the first one's objects.
- The brand registration's default is still a `fatalError`, now with a message, reachable only by a test container made without a brand. The in-memory fallback's `try!` is a `fatalError` that says SwiftData can't start.
- `BrandBootstrapTests` resolves every registration by name, and checks that list against the `Factory` declarations in `Container+AppShell.swift`, so a new registration has to be added to it.
- The in-app tests reach the running app through `AppShell.launched` (main-actor, weak), which the app itself never reads.

## Consequences

**Better:** a flow's dependencies are its initializer; a flow test builds one through `AppComposition(container:)` with fakes registered, and a flow can no longer reach a service it doesn't declare. Nothing can resolve before the brand. Two compositions (two tests) never share objects.

**Limits, honestly:**
- Still Factory underneath, so a factory that resolves an unregistered key fails at runtime, not compile time. Making the whole graph typed (no container) would mean hand-writing ~30 registrations as properties; the bootstrap test covering every key is the cheaper guard.
- `AppShell.launched` is a global, for tests only.

## Alternatives

- **Keep `Container.shared` and only document:** leaves the service locator in every flow.
- **A per-flow `Dependencies` struct:** one more type per flow for what an initializer already says.
- **Drop Factory:** the composition would hand-build everything; more code for the same graph, and the factories' overrides in tests would need a replacement.
