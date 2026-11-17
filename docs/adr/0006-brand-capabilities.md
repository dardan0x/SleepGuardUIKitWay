# ADR 0006: Brand capabilities are ports or values the brand states

- **Status:** Accepted
- **Date:** 2026-11-17
- **Task:** F8-T1

## Context

Settings is the first screen whose rows differ by brand. SleepGuard and Nocturne write nights to Apple Health; SleepGuard Lite doesn't link HealthKit at all (ADR 0003). No brand is on the App Store yet, so "Rate on App Store" has nowhere to go. None of the three has a Watch app, which SleepGuard's Settings has a section for.

`BrandConfiguration` held only a theme and the tabs. A flag such as `usesHealthKit: Bool` would let the shell know that Health exists, but not reach it: the shell can't import `SleepHealth`, because Lite doesn't link it.

## Decision

- **A capability that needs a framework only some brands link arrives as a port the brand builds, or `nil`.** `BrandConfiguration.health: (any HealthAccess)?`: SleepGuard and Nocturne pass `SleepHealth.makeHealthAccess()`, Lite passes `nil`. The shell registers whatever it got. `CommitSession` writes to Health only when there is a port and the person turned sync on. Settings shows the Health row only when there is a port.
- **A capability that is data is a value.** `appStoreID: String?`: the rating row appears once a brand has one.
- **Every brand states every value.** The initializer has no defaults, so a new capability is a compile error in each brand until it decides.
- **No flag for what no brand has.** There's no Watch app, so there's no `watch` flag: the shell passes no Watch section to the shared Settings content. A Watch brand would add the port then.
- Brand differences are still read only in the container, coordinators and composers, never in a feature (`if brand ==` stays banned).

## Consequences

- Lite has no HealthKit code, entitlement or usage text, and nothing in the shell had to change for it.
- The shared Settings content takes each optional section or row as an optional value; the same mechanism serves SleepGuard's remote feature flags.
- The cost: `BrandConfiguration` imports `SleepDomain` for the port type. That's the domain, which the shell already depends on.
- F8-T3 (sleep stages): `HealthAccess` refines `SleepStagePort`, so a brand's Health port also reads the stages; the container uses it, or `NoSleepStages` when the brand has no Health (Lite). Stages are read whenever the brand has Health; Health's own permission is the gate.
- F8-T4 (Snore Interrupter): `snoreInterrupter: Bool`, a value, because every brand links AVFoundation; Lite says `false`. The container makes the melody store only when it is on, and the composer turns it into the prestart's `hasInterrupter` and the night's `SnoreInterrupter`.
- F8-T5 (Learn): whether a brand has the tab is its `tabs` list (Lite leaves `.learn` out); the page is `learnURL: URL?`, a value. SleepGuard's comes from Remote Config, which this app doesn't have; `nil` shows the shared "No content available".

## Alternatives

- **Boolean flags plus a Factory registration in each brand's app target.** Two places to keep in step, and the flag could say yes while nothing was registered.
- **Linking `SleepHealth` in Lite and hiding the rows.** Lite would ship HealthKit code and need its usage texts, the opposite of what ADR 0003 decided for Lite.
