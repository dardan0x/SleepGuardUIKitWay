# ADR 0012: Links open through the app coordinator

- **Status:** Accepted
- **Date:** 2026-11-26
- **Task:** F13-T12 (architecture review Q28)

## Context

Each brand declares a URL scheme (Tuist brand list, Info.plist) and AGENTS.md said links parse to an `AppRoute` handled by `AppCoordinator`, but nothing handled them.

## Decision

- `AppRoute` parses `start`, `session/<id>` and `last7nights`, SleepGuard's widget paths. iOS only hands the app its own scheme, so the scheme isn't checked.
- The scene delegate passes the launch link and later ones to `AppCoordinator.open(_:)`.
- `AppCoordinator` opens a route only when the app is free: tabs up, no night recording, no sheet (one being dismissed doesn't count). Otherwise it keeps the latest route and opens it once the briefing or the night closes. "Start" during a night is dropped. Routes live in memory only.
- A night opens in Sessions, or Statistics when the brand has no Sessions tab, from the tab's root; a night that no longer exists changes nothing. Last 7 Nights opens from Statistics.

## Consequences

**Better:** the schemes the brands declare work, and a link can't land a screen under a recording or into a closing sheet.

**Limits, honestly:** one pending route at a time (the latest wins); no universal links; the system's "Open in …?" prompt wasn't exercised in automation (covered by tests on the coordinator, not on a device).

## Alternatives

- **Route in the scene delegate:** it would need to know about flows and recording state.
- **Drop links while busy:** a widget tap during the briefing would do nothing.
