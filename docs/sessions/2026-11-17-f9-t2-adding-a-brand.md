
### Completed
- F9-T2: Dawn, a fourth brand, added as the worked example in `docs/ADDING_A_BRAND.md`.

### Technical Details
- **Preparation**: `scripts/run-tests.sh` and CI listed the three brands by name. They now find every `Apps/<Name>/Sources/Brand.swift`, so a new brand needs no script edit.
- **Dawn**:
  - a `Brand.all` entry with HealthKit;
  - `Apps/Dawn/Sources/Brand.swift`: a warm sunrise theme, tabs Statistics / History / Settings, Apple Health, no Snore Interrupter, no Learn tab;
  - entitlements: app group and HealthKit;
  - asset catalog: a 1024 px opaque icon, drawn by a small AppKit script; `BrandAccent` and `LaunchBackground`.
- **The brand diff**: 8 files, 117 lines added, 1 removed, all in the brand folder and the brand list.
- **The bootstrap test**: needed no edit. It runs inside every brand's app, so it checked Dawn's container and tabs as soon as Tuist generated the target.

### Files Changed
| File | What Changed |
|------|--------------|
| `scripts/run-tests.sh`, `.github/workflows/ci.yml` | Brands found by folder (preparation) |
| `Tuist/ProjectDescriptionHelpers/Brand.swift`, `Apps/Dawn/**` | The brand |
| `docs/ADDING_A_BRAND.md` | New: the walkthrough with the real diff |
| `docs/ARCHITECTURE.md`, `AGENTS.md`, `CLAUDE.md` | Four brands |
| `docs/trackers/f9-showcase-polish.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | F9-T2 |

### Build Status
- In-app tests in all four brands, 9 each, passed on the first run. Layering, view-size and hardcoded-string checks pass. Packages unchanged.

### Next Session
- F9-T3: the same feature in both architectures, what each costs and buys.

### Open Questions
- Whether Dawn stays as a fourth shipped brand or only as the example (it costs a target and a CI build).
