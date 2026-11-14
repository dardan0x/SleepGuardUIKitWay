# ADR 0004: Share pure logic, strings and the design kit through `SleepGuardShared`

- **Status:** Accepted (design kit product not built yet)
- **Date:** 2026-11-14

## Context

This app and the SwiftUI app `SleepGuard` need the same sleep score, the same detection rules, the same strings and the same visual tokens. Copies would drift.

## Decision

Both apps consume one package from a separate repo, `../SleepGuardShared`:

| Product | Contents | State |
|---|---|---|
| `SleepCore` | Score formula and config, detection state machine and actor, stored value types | Extracted from SleepGuard, tests and replay goldens moved with it |
| `SleepStrings` | String catalog and generated `Strings` | Extracted from SleepGuard |
| `SleepGuardDesignKit` | `Theme` value, environment key, components with no domain types | To build in F1 |

Not shared: entities, ports, use cases, adapters, navigation, DI. Those are where the two apps intentionally differ.

In this app a file that uses a `SleepCore` type imports `SleepCore` explicitly. Strings are the one re-export: `SleepGuardDesignKit` re-exports `SleepStrings`, matching SleepGuard's `DesignSystem`, so view files need one import for tokens, components and strings. The owner chose this over an explicit `import SleepStrings` in every file; the cost is that a file's imports don't name where `Strings` comes from.

## Consequences

- One formula, one state machine, one catalog; tested once.
- A change in the shared repo affects both apps. For SleepGuard some shared value types are stored data, so their stored properties and raw values are frozen by its schema rules.
- **Limits:**
  - The dependency is currently a sibling path. The intended state is a versioned URL with the sibling checkout as a local override; that needs the shared repo to have a remote.
  - Strings are shared wholesale: this app carries strings for screens it hasn't built, and a wording change for one app changes the other.
  - The design kit has to stay free of domain types, which means features map domain values to the kit's view-data structs.

## Alternatives

- **Copy the code.** No coupling; two diverging implementations.
- **One repo per package.** A change spanning logic and strings needs two versions and two pins.
- **Depend on SleepGuard's packages directly.** They bring SwiftData models and Factory into the UI kit and can't carry more than one palette.
