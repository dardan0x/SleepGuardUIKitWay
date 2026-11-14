# SleepGuardUIKitWay: architecture proposal and roadmap

## Context

SleepGuard is a working SwiftUI app (12 local packages, ~17k lines, MV style, Factory DI, Swift 6). The goal is a second project that rebuilds it as a **UIKit shell hosting SwiftUI screens** on a Hexagonal/Clean core, with several white-label app targets, as a senior-level interview showcase. SleepGuard supplies the product, screens and visual language.

Decisions already made with you: **vertical slices first**, **Tuist**, **3 brands with distinct identities**, and **shared code lives in its own git repo used by both apps** (design system, pure domain logic, strings), so one change reaches SleepGuard and SleepGuardUIKitWay. See "Shared repo" in section C.

Nothing is created until this plan is approved. Name: I'd keep `SleepGuardUIKitWay` (alternative: `SleepGuardHybrid`); location `/Users/user/Documents/IndependentProjects/SleepGuardUIKitWay`, its own git repo.

---

## A. What exists today

### SleepGuard (verified against code)
- **Structure:** `Models`, `AudioEngine`, `Env`, `Routing`, `DesignSystem` + 7 feature packages; app target is the composition root. Swift 6 mode everywhere, zero `@unchecked Sendable`/`@preconcurrency`.
- **Presentation:** MV. Views hold `@State` + `ViewState` enums; `@Observable` state owners only for imperative resources (`SessionDetailModel`, `ClipPlaybackController`). Views resolve services with `@Injected`.
- **Navigation:** SwiftUI `NavigationStack` per tab driven by `RouterPath`; many sheets bypass `SheetDestination` with local `.sheet`.
- **Strong parts to keep:** pure `SleepScore.compute`, pure `DetectionStateMachine` + `DetectionEngine` actor fed by one ordered `AsyncStream` (ADR 0003), replay goldens, protocol-per-service with fakes, CI layering scripts.
- **What blocks a hexagonal port:**
  - SwiftData `@Model` classes *are* the domain objects. 59 UI files reference `SleepSession`/`SnoreEvent`; 6 views use `@Query`; 10 views use `modelContext`; service protocols take `ModelContext` (`SessionCommitting.commit(_:in:)`).
  - Domain rules live in the wrong place: episode merging and snoring duration are computed properties on the `@Model`; sensitivity thresholds are in `RealtimeDetectionTracker` (Env).
  - The in-progress night is an unsaved `@Model` mutated in memory.
  - Persistence logic is duplicated in views (delete ordering and fault workarounds in 3 places, `fetchOrCreateProfile()` in 2 tabs).
  - Flows depend on a tab: crash-recovery and session summary only work because `StatisticsTab` observes `sessionManager.completedSession`.
  - Brand identifiers are hard-coded in shared code (app group id, URL scheme, log subsystem).
  - `DesignSystem` depends on `Models` and Factory, has one palette, and holds all 453 strings.

### What carries over from SleepGuard

| Keep | Adapt | Discard |
|---|---|---|
| Screens, visual language, MV + `ViewState`, pure score/detection logic, ADR 0003 pipeline, replay goldens, Swift Testing, layering scripts | Views take data and actions through init instead of `@Query`/`@Injected`; theme via SwiftUI environment; `@Model` becomes a persistence record behind a mapper | `@Query`/`modelContext` in views, `.shared` singletons, `NavigationStack`/`RouterPath`, local `.sheet` for screens, NotificationCenter as an event bus, `@Model` in service protocols |

### Design choices for the new shell

| Topic | Choice | Ruled out |
|---|---|---|
| I/O boundaries | Ports in the domain, adapters at the edges with records and mappers `internal`; one adapter module per framework so a brand links only what it uses; a `NoOp` adapter where a brand lacks a capability | Framework types in feature or domain signatures |
| Dependency injection | Factory only in the app layer; modules take plain initializer injection; a composer is the one place that resolves from the container | `@Injected` in domain or screen code; a composer that doubles as a use-case factory |
| Hosting SwiftUI | A composer builds the screen and its dependencies and returns an opaque `UIViewController`; one generic hosting controller | A view model per screen; a hosting-controller subclass per screen |
| Navigation | One owner (coordinators); features expose intents as `@MainActor` closures | Ownership split between a router object and a coordinator; a single coordinator that grows to own every flow |
| Brands | A typed protocol each brand implements; capabilities as plain values | Placeholder registrations that `fatalError` until a brand overrides them; a brand enum in the domain or brand checks in policies; a global theme setter |
| Use cases | Only where a policy is applied or two or more ports are coordinated | One-line pass-through use cases |
| Project and language | Generated project file; Swift 6 language mode in every target; `.task` for loading | Hand-edited project file; Swift 5 mode app targets; `.onAppear` + fire-and-forget `Task` |
| Tests | `*TestSupport` products with fakes per port | Fakes duplicated per test target |

---

## B. Proposed architecture

```
Brand app targets (SleepGuard | SleepGuardLite | Nocturne)   brand config, assets, brand composition
        │
     AppShell            UIKit lifecycle, coordinators, composers, Factory container   (UIKit + Factory)
        │
  ┌─────┼──────────────┬───────────────┐
Features (SwiftUI)   ScreenKit        Adapters (SleepPersistence, SleepAudio, SleepHealth)
  │   │              (UIKit+SwiftUI)        │
  │   └── SleepGuardDesignKit (shared)      │
  └──────────────► SleepDomain ◄────────────┘      Foundation only
```

**Dependency rule:** everything points at `SleepDomain`; `SleepDomain` imports only Foundation. Features never import UIKit, Factory, adapters, or each other. Adapters never import features or SwiftUI. Only `AppShell` and brand targets see everything.

**Layer responsibilities**
- **SleepDomain:** entities and values (`SleepSession`, `SnoreEvent`, `SnoringEpisode`, `SleepStageSegment`, `RecordingDraft`), policies (pure: `SleepScore`, episode merging, `DetectionStateMachine`, sensitivity thresholds, minimum-save-duration), ports (`SessionRepository`, `ProfileRepository`, `PreferencesStore`, `AudioCapturePort`, `ClipPlaybackPort`, `SleepStagePort`, `SessionFileStore`), use cases.
- **Adapters:** implement ports. Framework types (SwiftData, AVFoundation, HealthKit) stay inside; only `Sendable` domain values cross.
- **Features:** SwiftUI screens in MV style. Public surface per feature: the screen view, a `Dependencies` struct, a `Routes` struct.
- **ScreenKit:** the UIKit/SwiftUI bridge (`HostingScreen`, `ScreenChrome`, `Navigator`).
- **AppShell:** `AppDelegate`/`SceneDelegate` logic, coordinators, composers, the Factory `Container`. The only module that imports Factory.

**Data flow (example: open a night):**
`SessionDetailScreen` `.task` → `LoadSessionDetail` use case → `SessionRepository.session(id:)` + `SleepStagePort.stages(for:)` → score recomputed by `SleepScore` policy → repository saves cached score → returns `SessionDetail` value → view sets `viewState = .loaded`.

**Use-case rule:** a use case exists only when it applies a policy or coordinates two or more ports (`CommitSession`, `DeleteSession`, `LoadSessionDetail`, `BuildDashboard`, `EnforceStorageLimits`, `RecoverInterruptedSession`). For a plain read, the feature's `Dependencies` holds the port directly. No one-line pass-through use cases.

**Live data replaces `@Query`:** `SessionRepository.observeSummaries() -> AsyncStream<[SessionSummary]>`; list screens iterate it in `.task`.

**Navigation ownership (single owner):** coordinators perform every push, pop, present and dismiss. Features only emit intents through `Routes` closures. Screen-level modals are UIKit sheets (`UISheetPresentationController` detents). SwiftUI keeps only `.alert`/`.confirmationDialog`. `UIKit` owns the navigation bar through `ScreenChrome`; features don't use `.navigationTitle`, `.toolbar`, `.sheet`, `NavigationStack` (CI grep).

```
AppCoordinator ── onboarding | MainTabCoordinator (UITabBarController, tabs from BrandConfiguration)
                               ├─ StatisticsFlow (UINavigationController)
                               ├─ HistoryFlow
                               ├─ SettingsFlow
                               └─ RecordingFlow (full-screen modal; owns summary + recovery, no tab dependency)
```
Deep links: `AppRoute` enum parsed in `SceneDelegate`, handled by `AppCoordinator`. This fixes SleepGuard's "summary only appears if Statistics tab exists" coupling.

---

## C. Project structure

Modules are **local Swift packages** (compiler-enforced boundaries, internal adapters, macOS `swift test` for the domain). **Tuist** generates only the app targets from one brand list.

```
SleepGuardUIKitWay/
  Project.swift, Tuist/ProjectDescriptionHelpers/Brand.swift   # brands = [.sleepGuard, .lite, .nocturne]
  Apps/
    Shared/            main.swift, Info.plist template, LaunchScreen
    SleepGuard/        Brand.swift (BrandComposition), Assets.xcassets (AppIcon, launch colour), .xcconfig, entitlements
    SleepGuardLite/    same shape
    Nocturne/          same shape
  Packages/
    Core/              products: SleepDomain (entities, ports, use cases; depends on shared SleepCore), SleepDomainTestSupport
    Adapters/          products: SleepPersistence (SwiftData, files, UserDefaults), SleepAudio (AVFoundation, SoundAnalysis, Accelerate), SleepHealth (HealthKit)
    Presentation/      products: ScreenKit
    Features/          products: HistoryFeature, SessionDetailFeature, StatisticsFeature, later RecordingFeature, SettingsFeature, OnboardingFeature, PersonalizationFeature, LearnFeature
    AppShell/          products: AppShell, AppShellTestSupport
  scripts/             check-layering.py, check-view-size.py (ported from SleepGuard)
  docs/adr/, docs/ARCHITECTURE.md, docs/ADDING_A_BRAND.md
../SleepGuardShared/      # separate git repo, one Package.swift, consumed by both apps
```

One domain module, not per-feature domains: SleepGuard's domain is one cohesive model (session, events, score) used by every feature. Splitting it would be ceremony.

### Shared repo: `SleepGuardShared`

One repo, one `Package.swift`, three library products plus test support. One repo (not one per package) so a change that spans logic and UI is one commit and one version.

| Product | Imports | Contents | Moved from SleepGuard |
|---|---|---|---|
| `SleepCore` | Foundation | Pure values and policies: `SleepScore`, `SleepScoreConfig`, `SleepInputs`, cache-version hash, `SnoreBurst`, `RecordingGap`, `SleepStageSegment`, `StageStats`, `SoundCategory`, `SnoreIntensity`, episode-merging and snoring-duration rules as pure functions, `DetectionStateMachine`, `DetectionEngine`, `DetectionInput/Output`, snore/speech classification rules, sensitivity thresholds | `Models/Sources/Data/SleepScore*.swift`, value types in `Models`, `AudioEngine` detection files, threshold table from `Env/RealtimeDetectionTracker` |
| `SleepCoreTestSupport` | SleepCore | Fixtures, replay CSVs + goldens, re-record script | `AudioEngine/Tests/Fixtures/Replay`, `scripts/record-replay-goldens.sh` |
| `SleepGuardDesignKit` | SwiftUI | `Theme` value type (`Palette`, `Typography`, `Radii`), `@Environment(\.theme)`, components with no domain types (`StatCard`, `SleepScoreGauge`, `MiniBarChart`, `AudioLevelMeter`, buttons, `SheetHeader`, `ScaleButtonStyle`; timeline/hypnogram/stats grid taking view-data structs) | `DesignSystem/Sources/Components`, `Theme.swift` tokens |
| `SleepStrings` | Foundation | `Localizable.xcstrings`, generated `Strings`, `generate-strings.py` / `generate-xcstrings.py`. The 3 strings containing "SleepGuard" take the brand name as an argument | `DesignSystem/Sources/Resources`, `Strings.swift`, `scripts/generate-*.py` |

**How shared strings work (no library needed):** a Swift package can carry its own string catalog as a resource, and `String(localized:bundle: .module)` reads it from whichever app links the package. SleepGuard's generator already emits exactly that form, so the catalog, `Strings.swift` and the two generator scripts move as they are.
- One change: `Strings` is currently main-actor-isolated only because `DesignSystem` sets default MainActor isolation. In `SleepStrings` (no default isolation) it becomes callable from anywhere, which also lets `BriefingEngine` stop importing `DesignSystem`.
- SleepGuard's CLAUDE.md localization section, the strings-in-sync CI check and the Xcode "Generate Strings.swift" build phase are updated to point at the shared repo.
- Alternatives considered: SwiftGen / R.swift (same result, extra dependency) and Xcode 26's built-in String Catalog symbol generation (would remove the script, but I haven't verified it for package resources; worth a spike in Phase 0, not a dependency of the plan).
- Brand-specific wording: strings that name the app take the brand name as a format argument supplied by each app; no per-brand catalogs.

**Stays app-specific (not shared):** SleepGuard's SwiftData `@Model` classes, `Env` services, its `Theme`/`ThemeProviding` + Factory registration, navigation; the new app's entities, ports, use cases, adapters, shell. These are exactly where the two architectures differ.

**How a change reaches both apps**
- **Day to day (instant):** both apps sit beside a local checkout (`IndependentProjects/SleepGuardShared`). Each app's project/workspace includes that folder as a local package, which overrides the remote dependency of the same name. Edit a shared file, build either app, the change is there.
- **Committed state (reproducible):** both apps declare `.package(url: <SleepGuardShared remote>, from: "x.y.z")`. A shared change is released by tagging; `scripts/bump-shared.sh` in each app updates the pin. CI builds from the tag, never from a sibling folder.
- **Guard rail:** the shared repo's CI builds and tests the package, then builds both apps against the candidate commit, so a shared change can't silently break either.
- To verify in Phase 0: that SleepGuard's per-package test runs (`scripts/run-tests.sh`) pick up the local override; if they don't, they use the pinned tag, which is acceptable.

**Migrating the original SleepGuard onto it** (this edits the working app, on its own branches, with an ADR):
1. **Core logic (Phase 0, move not copy):** files move to `SleepCore` with names unchanged; `Models` and `AudioEngine` depend on it and add `import SleepCore` at use sites. `@Model` computed properties (`snoringDuration`, `snoringEpisodes`) become one-line calls into the pure functions. `check-layering.py` learns the new module.
2. **Strings (Phase 0):** `DesignSystem` re-exposes `SleepStrings.Strings` under the same name (`typealias`), so no call site changes.
3. **Design kit (Phase 5b):** `DesignSystem` depends on the kit, keeps its `Theme`/`ThemeProviding` built from the kit's default palette, and injects `\.theme` at the root. The 131 `@Injected(\.theme)` sites in feature views are untouched; only the ~24 moved components and their 11 domain-typed call sites change. Checked against `designs/SleepGuard.pen`. Done after two slices of the new app have settled the kit's API.

**Risks**
- `RecordingGap`, `SleepStageSegment`, `SnoreBurst` and the enums are stored inside SwiftData `@Model`s. Moving them to another module should not change the store, but I haven't verified it. Phase 0 includes a `SleepGuardSchemaTests` case that opens a pre-move on-disk store, plus a check on a simulator holding real data, before merging.
- Detection output must not change: the replay goldens must pass unmodified after the move.
- Creating the remote repo and pushing is outward-facing; I'll ask before doing it (private repo assumed).

### White-label

| Brand | Identity | Features | Links |
|---|---|---|---|
| SleepGuard | current dark blue (`#5E9CFF`) | everything | all adapters |
| SleepGuard Lite | teal accent | no HealthKit stages, no Snore Interrupter, no Learn tab; 3 tabs | no `SleepHealth`, no HealthKit entitlement |
| Nocturne | violet/amber palette, rounded type, History tab first | everything | all adapters |

- **Per brand (the only brand-specific files):** `Brand.swift`, asset catalog, xcconfig (bundle id, display name, URL scheme, app group), entitlements. Everything else is shared.
- **Typed composition instead of `fatalError` placeholders:**
  ```swift
  public protocol BrandComposition {            // AppShell
    var configuration: BrandConfiguration { get }   // name, urlScheme, appGroup, theme, tabs, capabilities
    func makeSleepStagePort() -> any SleepStagePort // Lite returns NoOpSleepStagePort()
  }
  ```
  A brand that forgets a binding fails to compile. `AppShell.bootstrap(brand:)` registers these into the `Container` once.
- **Feature availability without brand checks:** `BrandConfiguration.capabilities` (a struct of flags) is read in exactly two places: coordinators (which tabs/flows exist) and composers (which pass plain values such as `showsSleepStages: Bool` into a feature's `Dependencies`). Features and domain never see a brand. No brand enum.
- **Theme:** `HostingScreen` injects `configuration.theme` into the SwiftUI environment; `AppShell` applies the same theme to `UINavigationBarAppearance`/`UITabBarAppearance`.
- **Guard rail:** a test that bootstraps each brand and resolves every registration.

---

## D. SwiftUI integration strategy

Four pieces, each with one job:

| Piece | Module | Job |
|---|---|---|
| `Screen` view + `Dependencies` + `Routes` | Feature | UI, state, intents. No UIKit, no Factory |
| `HostingScreen<Content>` | ScreenKit | The one `UIHostingController` subclass: injects theme, applies `ScreenChrome` (title, bar items), sets background |
| `Navigator` protocol | ScreenKit | `push/pop/present/dismiss`; implemented over `UINavigationController`; spied in tests |
| `…ScreenComposer` | AppShell | Resolves from `Container`, builds `Dependencies` and the view, returns `UIViewController` |

```swift
// HistoryFeature (SwiftUI only)
public struct HistoryDependencies: Sendable {
  public var sessions: any SessionRepository       // plain read: port directly
  public var deleteSession: DeleteSession          // use case: policy + file cleanup
}
public struct HistoryRoutes {
  public var openSession: @MainActor (SleepSession.ID) -> Void
  public var startRecording: @MainActor () -> Void
}
public struct HistoryScreen: View {
  public init(dependencies: HistoryDependencies, routes: HistoryRoutes)
  @State private var viewState: ViewState = .loading
  // body: switch viewState { … }  .task { for await list in dependencies.sessions.observeSummaries() { … } }
}

// AppShell
@MainActor struct HistoryScreenComposer {
  let container: Container
  let theme: Theme
  func make(routes: HistoryRoutes) -> UIViewController {
    let view = HistoryScreen(
      dependencies: .init(sessions: container.sessionRepository(), deleteSession: container.deleteSession()),
      routes: routes)
    return HostingScreen(rootView: view, theme: theme, chrome: .init(title: Strings.historyTitle, largeTitle: true))
  }
}

// AppShell: HistoryFlow (coordinator)
func start() {
  navigator.setRoot(composer.make(routes: .init(
    openSession: { [weak self] id in self?.showDetail(id) },
    startRecording: { [weak self] in self?.onStartRecording() })))
}
```

- **State ownership:** SwiftUI owns screen state (`@State`); its lifetime equals the hosting controller's. An `@Observable` state owner is added only for an imperative resource (clip playback), built by the composer and passed in.
- **Why no view models:** behind a hosted SwiftUI screen, a view model would only hold `@Published` state and call a router. `@State` + `Routes` does both with less code, and the logic worth testing lives in use cases and policies. Coordinators are tested with a `NavigatorSpy`.
- **Lifecycle:** loading in `.task` (cancelled on disappear) with a guard so popping back doesn't refetch. Swipe-back keeps working because UIKit owns the back button.
- **Why closures, not a `Routing` protocol:** a routing protocol has to be implemented by a router object that needs a weak `presenter` set after construction. Closures captured by the coordinator need neither the extra type nor the two-step init.

---

## E. Swift 6 strategy

- **All targets in Swift 6 language mode**, including the three apps (not Swift 5 with complete checking). Set in `Package.swift` and the Tuist helpers.
- **Isolation by module:**
  - `SleepDomain`: no default isolation. Entities/values are `Sendable` structs; use cases are `Sendable` structs with `async` methods; ports are `Sendable` protocols.
  - Adapters: actors. SwiftData goes behind a `@ModelActor` store; `@Model` records never leave it and are mapped to domain values inside the actor. This removes the relationship-faulting crashes SleepGuard works around with cached fields.
  - Features, ScreenKit, AppShell: `.defaultIsolation(MainActor.self)`.
- **UIKit ↔ SwiftUI:** both are main-actor; `Routes` closures are typed `@MainActor`, so nothing hops.
- **Detection pipeline:** port ADR 0003 unchanged (one ordered `AsyncStream` into the `DetectionEngine` actor). The in-progress night becomes a `RecordingDraft` value owned by a `RecordingSession` actor instead of an unsaved `@Model`. Live UI state is an `AsyncStream<LiveSnapshot>` at 5 Hz. NotificationCenter-as-event-bus is replaced by stream messages.
- **Tasks:** `.task` for loading; coordinators store and cancel their tasks; no fire-and-forget `Task` in load paths, so tests `await` instead of polling.
- **Factory:** `Sendable` ports get nonisolated factories; main-actor objects get `@MainActor` factories. Only `AppShell` resolves.
- **Escape hatches:** `@unchecked Sendable`, `nonisolated(unsafe)`, `@preconcurrency` are banned by the layering script, test fakes included (fakes are actors). One documented exception: the lock in the realtime audio tap (`OSAllocatedUnfairLock`), because the render thread cannot await.
- **Known hard spots:** `installTap` and `AVAssetWriter` callbacks (SDK closures the compiler doesn't check), `@ModelActor` observation (emit after each write rather than observing the context), HealthKit queries bridged with continuations.

---

## F. Roadmap

| Phase | Deliverable | Depends on |
|---|---|---|
| 0. Shared repo | Create `SleepGuardShared`; move `SleepCore` (+ tests, goldens) and `SleepStrings` out of SleepGuard; SleepGuard consumes them; all SleepGuard tests and goldens green; schema-compat test; tag `0.1.0`; shared-repo CI building SleepGuard | — |
| 1. Foundation | Repo, Tuist project, package skeletons, `SleepGuardDesignKit` product in the shared repo (tokens + primitive components), `ScreenKit`, `AppShell` with empty themed tab shell, 3 brands launching with their own icon/palette/tabs, CI (generate, build 3 brands, tests, layering script), ADRs 0001–0004 | 0 |
| 2. Domain + persistence | Entities, ports and use cases on top of `SleepCore`, `SessionRepository` on `@ModelActor`, mappers, Debug sample-night seeder | 1 |
| 3. Slice: History → Session Detail | List with live updates, push to detail, delete, events sheet (UIKit sheet). First full composer/coordinator example and `NavigatorSpy` tests | 2 |
| 4. Slice: Statistics | Dashboard, trends, calendar, last 7 nights; `BuildDashboard` use case from `DashboardState.make` | 2 |
| 5. Clip playback | `ClipPlaybackPort` + AVAudioEngine adapter, player sheet | 3 |
| 5b. Migrate original SleepGuard onto the design kit | Separate branch in SleepGuard, ADR, pen-file check | 4 |
| 6. Recording + detection | Detection comes from shared `SleepCore`; build `SleepAudio` capture adapter, `RecordingFlow`, `CommitSession`, summary, crash recovery | 2, 5 |
| 7. Remaining features | Settings, onboarding, HealthKit stages (not in Lite), Snore Interrupter (not in Lite), Learn (not in Lite), personalization/briefing | 6 |
| 8. Showcase polish | `ARCHITECTURE.md` with `tuist graph`, `ADDING_A_BRAND.md`, before/after comparison with SleepGuard | all |

Moved into the shared repo (Phase 0): `Packages/Models/Sources/Data/SleepScore*.swift`, `DetectionStateMachine.swift`, `DetectionEngine.swift`, `Tests/Fixtures/Replay/`, the string catalog and generators. Ported into the new app only: `Packages/Statistics/**/DashboardState.swift`, `SessionGrouper`, `scripts/check-layering.py`, `check-view-size.py`.

**Assumptions (say if any is wrong):** iOS 17 minimum; fresh data store (no migration from SleepGuard's); Firebase dropped, replaced by a `RemoteConfigPort` with a static per-brand adapter; widgets and Watch out of scope; bundle ids `com.dardan.sleepguardway.{sleepguard,lite,nocturne}`.

---

## G. Recommendations and pushback

- **Is a UIKit shell the right call?** For a greenfield iOS 17 app, `NavigationStack` is less code. The shell earns its place here for specific reasons: one owner for every transition, flows (recording, summary, recovery) that don't depend on a tab's view being alive, and proof that you can run both frameworks together. State that trade-off in the README; an interviewer will ask.
- **Where this departs from the usual Clean/coordinator template:** keep the boundaries but drop three habits: view models for SwiftUI screens, a use case for every call, and a routing protocol + router object per feature. Each adds types without adding tests worth having in this app.
- **Shared repo:** sharing the pure logic is the high-value part: one score formula and one detection state machine, tested once, running in both apps. Sharing the design kit is worth it for tokens and primitive components; that migration edits a working app, so it waits until the kit has had two slices of real use (Phase 5b). Don't share more than the table lists: entities, ports and navigation are where the two apps are meant to differ.
- **Keeping complexity down:** one domain module; one hosting controller; one composer shape; brand differences confined to `Brand.swift` + assets; CI scripts that fail the build on a forbidden import instead of a 1,300-line component catalog.
- **What makes it a stronger showcase:**
  - Adding a brand is one list entry + one folder, demonstrated by a doc and the per-brand resolution test.
  - A missing brand binding is a compile error, not a launch crash.
  - `@ModelActor` persistence that removes a real production crash class.
  - Deterministic detection tests (replay goldens) and zero concurrency escape hatches, gated in CI.
  - Coordinator tests through `NavigatorSpy`.
  - Short ADRs for each decision above, including the ones that reject a common pattern.

---

## Verification

- Phase 0: `swift test` in `SleepGuardShared`; `sh scripts/run-tests.sh` and an app build in SleepGuard pass against it with replay goldens unchanged; schema-compat test passes. Sharing check: edit one string and one `SleepScore` constant in the local shared checkout and confirm both apps pick it up on the next build.
- `tuist generate` succeeds; `xcodebuild build` for each of the 3 schemes on the pinned simulator, Swift 6 mode, zero warnings-as-errors.
- `swift test` (macOS) for `SleepDomain`; simulator tests for adapters, features with logic, and `AppShell` (coordinators, per-brand registration resolution).
- `python3 scripts/check-layering.py` passes (forbidden imports, escape hatches, SwiftUI navigation APIs in features).
- Manual per phase: launch each brand, confirm palette, tab set and gated features differ; from Phase 3, open a seeded night, delete it, and see the list update without a refetch on pop.
- XcodeBuildMCP and the iOS simulator MCP failed to connect this session; verification would fall back to `xcodebuild` in the shell unless they reconnect.
