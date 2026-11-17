
### Completed
- F10 planned with the owner and F10-T1 done: screen content moves to a new shared product (`SleepGuardContentKit`); screens stay in each app.

### Technical Details
- Analysis: components are shared already; what was still written twice is each screen's loaded layout (about 900 of this app's 1,900 feature lines; the matching views in SleepGuard's Statistics, Recordings and SleepSession packages), plus the month-and-day grouping rule.
- Not shared, on purpose: screens (loading, dependencies, navigation, alerts, the bar), state owners, `ScreenChrome`.
- A separate product rather than the design kit, so the kit stays free of product decisions.
- No shared release in T1: the product ships with its first content in T2.

### Files Changed
| File | What Changed |
|------|--------------|
| `docs/adr/0005-shared-screen-content.md` | New ADR |
| `AGENTS.md`, `CLAUDE.md` | The three layers and the test; features may import the content kit |
| `scripts/check-layering.py` | `SleepGuardContentKit` in `FEATURE_IMPORTS` |
| `docs/trackers/f10-shared-screen-content.md` | New tracker (6 tasks) |
| `docs/FeatureTracker.md`, `docs/Roadmap.md`, `docs/trackers/f8-remaining-features.md` | F10 before F8; F8 content-first |

### Build Status
- Docs and one script table only; layering check passes.

### Next Session
- F10-T2: the product, the four Statistics screens' content, adoption in SleepGuard and here.
