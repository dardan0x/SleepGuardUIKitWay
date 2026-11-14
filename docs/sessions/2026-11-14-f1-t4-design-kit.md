### Completed
- F1-T4: new `SleepGuardDesignKit` product in `SleepGuardShared` (branch `feature/f1/t4-design-kit`).
  - `Theme` value (`Palette`, `Typography`, `Radii`), `@Environment(\.theme)`, `Theme.sleepGuard` = SleepGuard's tokens, `Color(hex:)`.
  - Ten components ported from SleepGuard's `DesignSystem`: `StatCard`, `SleepScoreGauge`, `MiniBarChart`, `AudioLevelMeter`, `SheetHandle`, `SheetNavHeader`, `ScaleButtonStyle`, `RecordingActionButton`, `StartRecordingButton`, `StopRecordingButton`.
  - Re-exports `SleepStrings`.
  - An internal gallery with previews in two themes; render tests.
- Shared CI, test script and README cover the new product.

### Technical Details
- `@Injected(\.theme)` (Factory singleton) → `@Environment(\.theme)` (value). Components have no DI and no domain types.
- Hard-coded colours in the recording buttons and sheet handle → tokens (`destructive`, `bgCard`, `textTertiary`), so a brand can restyle them.
- Text fonts go through `Typography.font(size:weight:)` (one `Font.Design` per theme); large numbers stay `.rounded`.
- Render tests run on the simulator lane only: `ImageRenderer.uiImage` is UIKit, and `swift test` on macOS compiles every test target, so the file is wrapped in `#if canImport(UIKit)`.

### Files Changed
| File | What Changed |
|------|--------------|
| `SleepGuardShared/Package.swift` | `SleepGuardDesignKit` product and its test target |
| `SleepGuardShared/Sources/SleepGuardDesignKit/**` | Theme, environment key, components, gallery |
| `SleepGuardShared/Tests/SleepGuardDesignKitTests/DesignKitRenderTests.swift` | Renders in two themes; renders differ; score bands |
| `SleepGuardShared/scripts/run-tests.sh`, `.github/workflows/tests.yml`, `README.md` | Run and document the kit |
| `docs/trackers/f1-foundation.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | Status |

### Architecture Decisions
- Theme as an environment value rather than an injected `@Observable` singleton (ADR 0003).
- The kit doesn't depend on `SleepCore`: intensity and stage colour helpers arrive with the components that need them (F3-T5).

### Build Status
- Shared: `SleepCoreTests` 28 passed (macOS); `SleepGuardDesignKitTests` 3 and `SleepStringsTests` 2 passed (simulator). SwiftFormat clean.
- Both gallery renders reviewed by eye: every colour, the type design and radii follow the theme.
- SleepGuard through its dev workspace, against this shared branch: **BUILD SUCCEEDED**.
- `designs/SleepGuard.pen` could not be read: the Pencil app was not running.
- Not verified: against `designs/SleepGuard.pen` (layout unchanged from SleepGuard's components).

### Next Session
- After the shared PR is merged: tag `0.2.0`, then F1-T5 `ScreenKit` (bumps this app's packages to `0.2.0`).

### Open Questions
- `bg-card`: SleepGuard's `CLAUDE.md` says `#2C2C2E`, its `Theme.swift` uses `#22232B`. Which one does the design file use?
