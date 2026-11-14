# ADR 0002: Hexagonal core with a single domain module and a use-case rule

- **Status:** Accepted
- **Date:** 2026-11-14

## Context

In SleepGuard the SwiftData `@Model` classes are the domain objects. 59 UI files reference them, 6 views query the store, 10 views hold a model context, and service protocols take `ModelContext`. Business rules (episode merging, snoring duration) are computed properties on the models; delete ordering and fault workarounds are copied into three places; the in-progress night is an unsaved model mutated in memory.

Ports and adapters with internal mappers fix this. The usual Clean Architecture template goes further: a use case for every operation (many would be one forwarded call) and a domain folder inside each feature. Neither earns its place here.

## Decision

- **`SleepDomain` is Foundation-only** (plus `SleepCore`): entities and values as `Sendable` structs, pure policies, ports as `Sendable` async protocols, use cases as `Sendable` structs.
- **Adapters implement ports, one module per framework**, with records and mappers `internal`. SwiftData sits behind a `@ModelActor`; records never leave it.
- **One domain module**, not one per feature.
- **A use case exists only when it applies a policy or coordinates two or more ports.** A plain read uses the port directly from the screen's `Dependencies`.
- The in-progress night is a `RecordingDraft` value, not an unsaved record.

## Consequences

- Business rules are testable on macOS in seconds, with no store.
- The relationship-faulting crashes SleepGuard guards against cannot happen: nothing outside the store actor holds a record.
- Persistence can change (schema, even the framework) without touching features.
- **Costs:**
  - Mapping code between records and domain values, and a copy on every read.
  - Live lists need an explicit `AsyncStream` from the repository; `@Query` did that for free.
  - "When is it a use case?" is a judgment call. The rule and the table in `docs/architecture/domain.md` are the reference; reviewers enforce it.
  - Screens that hold a port directly depend on the port's shape. Acceptable: ports are domain-owned and small.

## Alternatives

- **Keep `@Model` as the domain (SleepGuard's approach).** No mapping, but UI and persistence stay welded together, which is the problem being solved.
- **A use case for everything.** Uniform, but most would be one-line forwards: more types, no more tests.
- **A domain per feature.** Features here share one model; it would be duplicated or re-centralised.
