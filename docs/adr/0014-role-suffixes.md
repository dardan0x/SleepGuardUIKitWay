# ADR 0014: Ports, use cases and adapters carry their role in the name

- **Status:** Accepted
- **Date:** 2026-11-27
- **Tasks:** F13-T24

## Context

Ports, use cases and adapters were named for their job alone: `SessionRepository`, `CommitSession`, `SwiftDataSessionStore`. Only the folder (`Ports/`, `UseCases/`, `Store/`) said which ring of the hexagon a type belongs to. At a call site, in a `Dependencies` struct or in a factory, you couldn't tell a port from a value or a use case from a function. The owner asked for the role in every name.

## Decision

The role is the suffix, in the type and in its file:

| Kind | Rule | Example |
|---|---|---|
| Port (`SleepDomain/Ports/`) | role + `Port` | `HealthAccess` → `HealthAccessPort`, `SessionRepository` → `SessionRepositoryPort` |
| Use case (`SleepDomain/UseCases/`) | action + `UseCase` | `CommitSession` → `CommitSessionUseCase`, `EnrichNightWithStages` → `EnrichNightWithStagesUseCase` |
| Adapter (this repo's adapter modules) | framework + port + `Adapter` | `HealthKitAccess` → `HealthKitAccessAdapter`, `SwiftDataSessionStore` → `SwiftDataSessionStoreAdapter` |
| Adapter module (and its factory namespace and test target) | area + `Adapter` | `SleepPersistence` → `SleepPersistenceAdapter`, `SleepAudio` → `SleepAudioAdapter`, `SleepHealth` → `SleepHealthAdapter` (`SleepHealthAdapter.makeHealthAccess()`) |

Also:
- One file per port: `SnoreInterrupterPorts.swift` became `MelodyPlayerPort.swift`, `MelodyStorePort.swift` and `MelodyRecorderPort.swift`. `PreferencesStorePort` moved out of `Settings/AppPreferences.swift`, and `HealthKitAccessAdapter` out of `SleepHealth.swift`.
- Test files and suites named after a renamed type follow it (`CommitSessionUseCaseTests`, `SwiftDataSessionStoreAdapterTests`).

Unchanged:
- **Fakes** (`FakeSessionRepository`): `Fake` already says what they are.
- **Factories, properties and parameters** (`makeHealthAccess()`, `let sessions: any SessionRepositoryPort`): they name the thing, not its kind.
- **The audio adapters**: they are the shared `SleepAudioKit`'s types (`CaptureEngine`, `ClipPlayerEngine`, …), which SleepGuard uses too. `KitConformances.swift` is this app's adapter; renaming the kit's types would rename SleepGuard's code to match this app's architecture.
- **History**: older ADRs, trackers, feature docs and session notes keep the names of their time.

## Consequences

- A type's role is visible wherever it's used: `any SessionRepositoryPort`, `CommitSessionUseCase(...)`, `SwiftDataSessionStoreAdapter: SessionRepositoryPort`.
- Some names repeat their role: `SessionRepositoryPort`, `ProfileStorePort`, `SleepStageSourcePort`. That's the cost of one rule with no exceptions.
- This goes against the Swift API Design Guidelines, which advise against naming a type for its kind (`…Protocol`). Here the suffix names an architectural role, not a language construct, which is the point of the showcase.
- Use cases are still called as functions (`commitSession(draft)`), so the suffix shows only where they're declared and built.
- Renaming a module touches the manifests, the Tuist brand linking (`usesHealthKit`), `check-layering.py`'s `ALLOWED_IMPORTS` and every `import`. Done once, mechanically.
- SleepGuardShared's docs, which describe this app, still use the old module names until that repo is updated.
- Older docs use the old names. Search for both when reading history.

## Alternatives

- **Rename only the adapters.** It was cheap (they're internal), but it would have left a half-applied convention.
- **Name adapter modules by framework** (`HealthKitAdapter`): `SleepPersistenceAdapter` wraps SwiftData, files and UserDefaults, so there's no single framework to name.
- **Leave the modules as they are**: Swift modules are usually named for their domain, not their kind. The owner chose one rule all the way up.
- **Prefixes or namespaces** (`Port.SessionRepository`): not idiomatic Swift, and they read worse in signatures.
- **Keep the folders as the only signal.** That was the old state, which the owner rejected.
