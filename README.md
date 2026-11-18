# SleepGuardUIKitWay

> A bedside sleep and snoring tracker for iOS. It listens while you sleep, detects snoring and sleep talking on the device, scores your night, and shows how your sleep trends over time.

Under the hood it's built the way a large UIKit team would build it: **UIKit screens and coordinators**, with the shared **SwiftUI** views as their cells and pages, on a **hexagonal core**, and **four white-label apps** ship from one codebase.

**One product, two architectures.** This is the UIKit-first sibling of [SleepGuard](https://github.com/dardan0x/SleepGuard), the same app built in pure SwiftUI. Both build against [SleepGuardShared](https://github.com/dardan0x/SleepGuardShared), which holds the domain rules, strings, design system and screen layouts. A night recorded here yields the same events, score and screens as in SleepGuard. Navigation, dependency injection, persistence boundaries, project generation and white-labelling are built differently, on purpose.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Language](https://img.shields.io/badge/Swift-6.2%20%C2%B7%20strict%20concurrency-orange)
![Architecture](https://img.shields.io/badge/architecture-UIKit%20%C2%B7%20SwiftUI%20content%20%C2%B7%20hexagonal-green)
![Build](https://img.shields.io/badge/project-Tuist-purple)
![Privacy](https://img.shields.io/badge/privacy-on--device-brightgreen)

Further reading: [Architecture](docs/ARCHITECTURE.md) (the full reference, checked against the code) · [Comparison with SleepGuard](docs/COMPARISON.md) (one feature in both shapes, with costs) · [Adding a brand](docs/ADDING_A_BRAND.md) (the real diff) · [ADRs](docs/adr/)

---

## What it does

| Capability | Notes |
|---|---|
| **Overnight recording** | Bedside clock with live level, delayed start, background recording, recovery of a night killed by the system |
| **Snore and sleep-talk detection** | SoundAnalysis confidence and sound level, classified per sample, turned into events by the shared detection state machine on its own actor |
| **Sleep score** | 0–100 from snoring time, episodes per hour, intensity, sleep talking, duration and, with Apple Health, sleep stages |
| **Playback** | Per-event clips, events in sequence, enhanced audio |
| **Statistics** | Dashboard, trends, calendar, Last 7 Nights |
| **Apple Health** | Writes nights, reads Watch sleep stages (brands with HealthKit only) |
| **Snore Interrupter** | A built-in or recorded melody when snoring starts; capture pauses while it plays |
| **Morning briefing, report, sharing** | Recap against your recent average with a lifestyle survey; a paged PDF report; clip sharing |

### Brands

| Brand | Theme | Capabilities |
|---|---|---|
| **SleepGuard** | SleepGuard's dark blue | Apple Health, Snore Interrupter, Learn |
| **Nocturne** | Violet, rounded type, Sessions tab first | Apple Health, Snore Interrupter, Learn |
| **SleepGuard Lite** | Teal | No HealthKit linked, no Interrupter, no Learn |
| **Dawn** | Warm sunrise | Apple Health; no Interrupter, no Learn |

A brand is a `BrandConfiguration` value, an asset catalog and an entry in the Tuist brand list. Adding Dawn changed 8 files (+117 lines) and no feature or domain code.

---

## Architecture: a hexagonal core inside a UIKit shell

### Why hexagonal

A sleep tracker's important logic sits next to the hardware and the system. One night touches the microphone, a classifier, the file system, SwiftData, HealthKit and an audio player. Three requirements made ports and adapters the right fit here:

- **The riskiest code must be testable without a device.** Recording a night, recovering it after a crash, committing it and scoring it are the behaviours users notice when they break. As use cases and an actor over ports, they run on macOS with `swift test` in seconds, against fakes.
- **Brands differ in infrastructure, not in behaviour.** SleepGuard Lite links no HealthKit. With a `SleepStagePort`, that's a composition decision (pass `nil`) rather than `#if` or brand checks across the codebase.
- **Frameworks are details with a shelf life.** SwiftData, AVFoundation and HealthKit each sit behind one adapter. Replacing one (a different store, a different capture pipeline) changes one module and its tests.

It also reflects how large iOS codebases tend to be organised: a UI layer that changes often, over a domain that shouldn't.

### How it works here

```
        driving side                                    core                                       driven side
┌──────────────────────────┐            ┌──────────────────────────────────┐            ┌────────────────────────────────┐
│ AppShell                 │            │ SleepDomain (application layer)  │            │ SleepPersistence               │
│   coordinators, flows,   │  calls     │   use cases: LoadSessionDetail,  │  ports     │   SwiftData @ModelActor,       │
│   factories              │ ─────────► │   CommitSession, DeleteSession,  │ ─────────► │   file stores                  │
│ Features                 │            │   MorningBriefing, …             │            │ SleepAudio                     │
│   UIKit screens via      │            │   RecordingSession (actor)       │            │   AVAudioEngine, SoundAnalysis │
│   Dependencies closures  │            │ ──────────────────────────────── │            │ SleepHealth                    │
└──────────────────────────┘            │ SleepCore (shared; domain model) │            │   HealthKit                    │
                                        │   Night, rules, DetectionEngine  │            └────────────────────────────────┘
                                        └──────────────────────────────────┘
```

- **The core has two rings.** `SleepCore` (from SleepGuardShared) is the domain model: entities and pure rules, shared with SleepGuard. `SleepDomain` is this app's application layer: it orchestrates those rules over ports. Neither imports an Apple framework beyond Foundation.
- **Ports are owned by the core and named for its needs**: `SessionRepository`, `SessionFileStore`, `AudioCapturePort`, `SleepStagePort`, `RecordingCheckpointStore`, `ClipPlayer`, `MelodyPlayer`, `ProfileStore`, `LifestyleLogStore`, and others (12 in all). Each has a fake in `SleepDomainTestSupport`.
- **Use cases are small values** composed from ports, invoked with `callAsFunction`:

```swift
public struct LoadSessionDetail: Sendable {
  public init(sessions: any SessionRepository, sleepStages: any SleepStagePort, scoreConfig: SleepScoreConfig = .default)

  public func callAsFunction(_ id: Night.ID) async throws -> SessionDetail {
    var session = try await sessions.session(id: id)
    if session.sleepStages.isEmpty,
       let stages = try? await sleepStages.stages(from: session.start, to: session.end), !stages.isEmpty {
      session.sleepStages = stages                                          // stages change the score,
      try await sessions.save(session, summary: session.summary(using: scoreConfig))   // so persist the new one
    }
    return SessionDetail(session: session, summary: session.summary(using: scoreConfig), episodes: session.displayableEpisodes)
  }
}
```

- **Adapters map at the boundary.** `SleepPersistence` stores its own SwiftData records and returns `Night` values; no `@Model` crosses a port. `SleepAudio` turns buffers into `CaptureSample`s; `SleepHealth` turns HealthKit samples into `SleepStageSegment`s.
- **The shell is the only place that knows both sides.** `AppShell` registers adapters against ports in the Factory container and hands use cases to screens as closures.

**Costs, stated plainly:** more files per feature, an explicit mapping in each adapter, and a composition root to maintain. For a single-brand app with a small team, SleepGuard's service-based shape is cheaper (see the comparison below).

---

## Modules

```
Apps/<Brand>             Brand.swift: BrandConfiguration (theme, tabs, Health port, capabilities)
└─► AppShell             composition root: coordinators, flows, factories, Factory container
    ├─► Features         8 modules of UIKit screens hosting the shared content: Dependencies in, Routes out
    ├─► ScreenKit        ScreenController, ContentListController, ScreenChrome, Navigator
    ├─► Adapters         SleepPersistence · SleepAudio · SleepHealth
    └─► SleepDomain      ports, use cases, RecordingSession actor
            └─► SleepCore and the kits (SleepGuardShared, pinned release)
```

| Layer | Module | Size | Responsibility | Must not |
|---|---|---|---|---|
| Domain | `SleepDomain` | 1.2k lines | 12 ports, 9 use cases, the `RecordingSession` actor, preferences. Written in `SleepCore` types | Import any Apple framework beyond Foundation |
| Adapters | `SleepPersistence` | 0.6k | SwiftData behind `SessionRepository` (`@ModelActor`); file stores for clips, checkpoint, profile, survey | Expose a `@Model` beyond its port |
| | `SleepAudio` | 1.1k | AVAudioEngine capture and analysis, clip compression and playback, melody player and recorder | |
| | `SleepHealth` | 87 | HealthKit read and write | Be linked by Lite |
| Presentation | `ScreenKit` | 0.4k | `ScreenController`, every screen's base (theme, chrome, one state child, hosting the shared views); a self-sizing UIKit list; the `Navigator` abstraction | |
| Features | 8 modules | 3.6k | 21 UIKit screens (collection views, a page view controller, alerts) around the shared SwiftUI content; the 14 with state or logic have a view model (ADR 0008): History, SessionDetail, Statistics, Recording, Settings, Onboarding, Briefing, Learn | Navigate, present anything but an alert, persist, resolve dependencies, use `UIApplication`; a view model imports no UI |
| Shell | `AppShell` | 1.8k | `AppCoordinator`, `MainTabCoordinator`, 9 flows, factories, 28 container registrations | Be imported by anything but the brand targets |

Dependencies point inwards. The domain knows no framework; adapters implement its ports; features know the domain's types and the shared content but not how they are presented; only `AppShell` knows everything.

---

## How the modules interact

A feature never calls another feature, the shell, or an adapter. Every interaction goes through one of four contracts:

| Contract | Direction | Defined in | Implemented by |
|---|---|---|---|
| **Port** | domain → infrastructure | `SleepDomain` (`SessionRepository`, `AudioCapturePort`, `SleepStagePort`, …) | Adapters |
| **Use case** | screen → domain | `SleepDomain` (`LoadSessionDetail`, `CommitSession`, `MorningBriefing`, …) | Itself; composed from ports |
| **`Dependencies`** | shell → screen (data in) | Each feature | `AppShell` factories |
| **`Routes`** | screen → shell (intent out) | Each feature | `AppShell` flows |

Opening a night from History exercises all four:

```
HistoryViewController ── viewModel.open(summary) ── routes.openNight(summary) ──► HistoryFlow
                                                  │
                                                  ▼
                                      NightDetailNavigation.show(summary)
                                                  │  SessionDetailFactory resolves LoadSessionDetail,
                                                  │  builds SessionDetailViewModel(dependencies:routes:), then
                                                  │  SessionDetailViewController(viewModel:theme:chrome:)
                                                  ▼
                                      navigator.push(controller)
                                                  │
SessionDetailViewModel ── await loadDetail(id) ──► LoadSessionDetail ──► SessionRepository ──► SleepPersistence
                                                                  └─► SleepStagePort    ──► SleepHealth, or none (Lite)
         │
         └─ a UIKit collection view of shared pieces (SleepGuardShared); Play / Share / Show all ──► SessionDetailRoutes ──► flow
```

The factory and the navigation object, from the source:

```swift
// AppShell: wiring only. Resolve, then the view model, then the screen.
let dependencies = SessionDetailDependencies(nightID: night.id, loadDetail: container.loadSessionDetail())
return SessionDetailViewController(
  viewModel: SessionDetailViewModel(dependencies: dependencies, routes: routes),
  theme: container.theme(),
  chrome: ScreenChrome(title: …, trailingItems: [reportItem, deleteItem]))

// AppShell: the flow decides what each intent does.
navigator.push(detail.make(
  night: night,
  onReport: { [weak self] in self?.shareReport(night.id) },
  onDelete: { [weak self] in self?.confirmDeleting(night.id) },
  routes: SessionDetailRoutes(
    showAllEvents: { [weak self] rows, events in self?.showEvents(rows, events) },
    playEvents: { [weak self] events, start in self?.play(events, from: start) },
    showStagesInfo: { [weak self] stages in self?.showStagesInfo(stages) },
    shareEvent: { [weak self] event in self?.shareClip(of: event) })))
```

Because `Navigator` is a protocol, a flow is tested against a spy that records pushes and presentations, with no UIKit window. Because `Dependencies` and `Routes` are plain values of closures, a screen is previewed and tested without a container.

**Long-running flows** belong to coordinators, not views. Recording is the clearest case. `RecordingFlow` owns the night's `LiveRecordingModel`, which drives the `RecordingSession` actor, from pre-start through countdown and the bedside clock to the summary, independent of tab switches. If the system kills a night, `AppCoordinator` recovers it from its checkpoint at the next launch and reopens the flow at the summary. Onboarding, the morning briefing and Learn are flows too, gated by brand configuration.

---

## How it uses SleepGuardShared

### How each module interacts with it

Each module imports the narrowest shared product it needs (from the manifests), and uses it for a specific job:

| Module | Imports | Shared types it works with | Role of the shared code |
|---|---|---|---|
| `SleepDomain` | SleepCore | `Night`, `NightSummary`, `SleepScoreConfig`, `DetectionEngine`, `SnoreClassifier`, `SpeechClassifier`, `AudioLevels`, `StoragePlan`, `BriefingEngine`, `BriefingSchedule`, `ProfilePrompt` | **Domain model.** Ports and use cases are typed in these entities. `RecordingSession` classifies each sample with the shared classifiers and streams it into the shared `DetectionEngine` actor. Use cases call the shared rules (storage plan, briefing, profile prompt) instead of reimplementing them |
| `SleepPersistence` | SleepCore | `Night`, `NightSummary`, `RecordingGap`, `SleepStageSegment`, `SleepProfile`, `LifestyleLog`, `RawLog` | **Mapping target.** Records are this module's own; it converts them to and from shared values at the port. The summary is stored next to the night, so lists never load events |
| `SleepAudio` | SleepCore, SleepMelodies | `AudioLevels`, `SpectralFeatures`, `SoundClassLabels`, `PlaybackGain`, `PlaybackEnhancement`, `WaveformAccumulator`, `Melody`, `CustomMelodies` | **Inputs and parameters.** The tap computes the shared detection inputs; playback uses the shared gain and filter settings; melodies resolve through the shared catalog and bundled files |
| `SleepHealth` | SleepCore | `SleepStageSegment`, `Night` | **Mapping target** for HealthKit samples, in both directions |
| `ScreenKit` | DesignKit | `Theme` | **Theming.** `ScreenController` sets the brand's `Theme` in the environment of everything a screen hosts, and gives UIKit text the theme's font |
| Features | ContentKit, SleepCore | Content views and pieces (`NightDayCard`, `NightDetailHeader`, `OnboardingPageView`, `StatisticsDashboardContent`, `BedsideClockContent`, `SettingsContent`, …) | **Drawing.** Each UIKit screen owns loading, state, alerts and its `Routes`, and hosts shared views as cells, pages or its whole content (ADR 0007) |
| `AppShell` | DesignKit, SleepCore | `Theme`, `Night`, `SleepStageSegment`, `RecordingGap`, `RecordingDelay` | **Composition.** Builds each brand's `Theme` and styles UIKit bars from its tokens; passes shared values between flows (a recovered night, a delay choice) |

### What stays here

The shared package contains no persistence, dependency injection, navigation or lifecycle. Those are this app's architecture:

- **Storage.** `SleepPersistence` has its own SwiftData records and maps them to `Night` at the port. SleepGuard's `@Model`s are never used here.
- **Composition.** Factory exists only in `AppShell`. Features receive closures and never see a container.
- **Navigation.** Coordinators and flows over `UINavigationController` / `UITabBarController`.
- **Brand variation.** Expressed through `BrandConfiguration`. A brand without HealthKit passes `nil` for the Health port. The shared content omits the stages card and the onboarding page because the value is absent, not because it knows about brands.

### Binding

| Mode | Command | Resolves to |
|---|---|---|
| Local (default) | `tuist generate` | `../SleepGuardShared`, so changes there build immediately |
| Release (CI) | `TUIST_SHARED_RELEASE=1 tuist generate` | The exact pinned version (`0.27.0`) |

Both modes use the same package identity, so manifests don't change between them. Adopting a new release means running `sh scripts/bump-shared.sh <version>` and then the full suite.

---

## Compared with SleepGuard (SwiftUI)

Same product, same shared core, different composition:

| Concern | SleepGuard | SleepGuardUIKitWay |
|---|---|---|
| **App structure** | SwiftUI `App`, tab views, local packages per feature | UIKit `UIApplication`, coordinators, local packages per layer |
| **Navigation** | `RouterPath` per tab; route enums mapped to views in the app target | Coordinators and flows; screens emit `Routes` closures |
| **Screen state** | `@State` + `ViewState` in the view; `@Observable` state owner for complex screens | The same inside each screen; presentation state lives in the flow |
| **Domain** | Services in `Env` and pure functions in `SleepCore` | Ports and use cases in `SleepDomain`, on `SleepCore` types |
| **Storage** | SwiftData `@Model`s read directly by views (`@Query`) | SwiftData records behind a port; views never see them |
| **Dependency injection** | Factory; `@Injected` in views | Factory in the shell only; screens get values |
| **Configuration** | Firebase Remote Config for flags | Static `BrandConfiguration` per brand |
| **Project** | Xcode project + workspace | Tuist; one app target per brand, generated |
| **Tests** | Models and services with fakes, in-memory SwiftData | Domain on macOS, flows over a navigator spy, hosted tests per brand |
| **Cost of one screen** (night detail) | ~500 lines in 4 files | ~480 lines in 9 files |

**Where SleepGuard is simpler:** less ceremony per screen, and `@Query` gives live updates for free. That is the right default for a small team on a new iOS 17 app.

**Where this shape pays off:** navigation that's unit-tested, flows that outlive any single view, a domain testable without a simulator, and brands that differ only in configuration. It is also the shape of most large existing UIKit codebases adopting SwiftUI incrementally.

The full analysis, including what each shape costs over time, is in [docs/COMPARISON.md](docs/COMPARISON.md).

---

## Concurrency and enforced boundaries

**Concurrency.** Swift 6 language mode with strict concurrency in every module. UI modules default to `MainActor`. Recording and detection run on actors, persistence on a `@ModelActor`. `@unchecked Sendable`, `nonisolated(unsafe)` and `@preconcurrency` are banned, except for one documented lock on the audio thread.

**Enforced boundaries.** Each of these runs in CI:

| Rule | Check |
|---|---|
| Each module imports only what its layer allows | `scripts/check-layering.py` |
| Features don't navigate, present, persist, resolve dependencies or touch `UIApplication` | `check-layering.py` |
| No singletons in packages; `os.Logger`, never `print` | `check-layering.py` |
| View file ≤ 200 lines; screen ≤ 100 | `scripts/check-view-size.py` |
| No user-facing literal outside `Strings` | `scripts/check-hardcoded-strings.py` |
| Every package builds alone, so undeclared imports fail | `run-tests.sh` packages lane |

---

## Testing

Testing follows the architecture: every boundary is a seam where a test double fits, so each layer is tested at its own level and the expensive tests are few.

| Level | Tested against | Examples | Runs on | Tests |
|---|---|---|---|---:|
| **Domain** (`SleepDomain`) | Fakes from `SleepDomainTestSupport`: one per port (repository, file store, capture, stage source, checkpoint store, players, settings) | Commit and delete ordering (a failed delete keeps the clips); the recording actor's events, gaps and checkpoints from scripted samples; briefing and storage rules over the shared engine | macOS, `swift test` | 65 |
| **Adapters** | Real infrastructure, isolated: in-memory or on-disk SwiftData, temporary directories, generated audio buffers | Session store round trip, replacement and observed summaries; checkpoint and settings stores; levels, classifier scores and clip compression on generated tones; clip player; HealthKit stage mapping | Simulator, per package | 40 |
| **Presentation** (`ScreenKit`) | Real UIKit, no window | `ScreenController` applies theme and chrome and swaps state; the content list; redraw on observed change; `Navigator` push, present and dismiss | Simulator | 17 |
| **Features** | View models with fake ports (no UIKit) | History's states and deleting a day; the detail's load, error, retry and sharing; onboarding permissions; prestart's microphone and charging checks; the countdown; a short night not saved; recording and picking a melody; Settings' ordered writes and confirmations; the list and detail item builders; `LiveRecordingModel`, `PlayerViewModel` | Simulator | 53 |
| **Shell** (`AppShell`) | `NavigatorSpy` + `TestBrand` from `AppShellTestSupport`; a container with fakes registered | Every flow: what each route pushes or presents, titles and bar items, confirmation before deleting, the briefing opening once per new night, a brand without the Interrupter getting no row and no melody at night | Simulator, no UI | 70 |
| **In-app** | The real app, per brand | Bootstrap, tabs, a night's detail, the player, the recording flow | Each brand's host app | 9 × 4 |

Two examples, from the source. A use case against fakes:

```swift
@Test func deletesTheRecordThenItsClips() async throws {
  let repository = FakeSessionRepository([session])
  let files = FakeSessionFileStore()
  try await DeleteSession(sessions: repository, files: files)(session.id)
  #expect(await repository.deletedIDs == [session.id])
  #expect(await Set(files.removed) == ["a.m4a", "b.m4a"])
}
```

A flow against a navigator spy. The screen's route is invoked directly, and the test asserts what the coordinator did:

```swift
@Test func openingANightPushesItsDetail() throws {
  let (flow, spy, _) = makeFlow([night])
  flow.start()
  try #require(rootList(spy)).viewModel.routes.openNight(night.summary())
  guard case let .push(pushed) = spy.calls.last else { Issue.record("expected push"); return }
  let detail = try #require(pushed as? SessionDetailViewController)
  #expect(detail.navigationItem.rightBarButtonItems?.map(\.accessibilityLabel) == [Strings.actionDelete, Strings.a11yExportReport])
}
```

**What is tested elsewhere.** The rules (score, detection, statistics, briefing) and every screen layout are tested once, in SleepGuardShared: 251 tests, including replay goldens recorded from a real night and renders of every screen in two themes. This repo doesn't re-test them; it tests that it composes them correctly. What only a device can verify (microphone over a full night, HealthKit permissions, a melody over a locked phone) is listed in the tracker as manual checks.

**How it runs.** `sh scripts/run-tests.sh` has three lanes: macOS (domain), packages (each built standalone with its own derived data, which also catches undeclared imports), and in-app (each brand discovered from `Apps/*`). CI runs all three on every PR against the pinned shared release.

---

## Getting started

Requirements: Xcode 26 (Swift 6.2), iOS 17+, [mise](https://mise.jdx.dev) for the pinned Tuist, and [SleepGuardShared](https://github.com/dardan0x/SleepGuardShared) checked out next to this repo.

```sh
mise install                 # pinned Tuist
tuist generate               # workspace, against ../SleepGuardShared
sh scripts/run-tests.sh      # all lanes
```

Run a brand's scheme (`SleepGuard`, `Nocturne`, `SleepGuardLite`, `Dawn`) on a simulator. Debug builds seed sample nights. Keep Xcode closed while `run-tests.sh` runs, because an open workspace holds package resolution.

**Where to look first:**

1. [`Packages/AppShell/Sources/AppShell/History/`](Packages/AppShell/Sources/AppShell/History/): a flow, its factories and a navigation object.
2. [`Packages/Core/Sources/SleepDomain/`](Packages/Core/Sources/SleepDomain/): ports, use cases, the recording actor.
3. [`Apps/Dawn/Sources/Brand.swift`](Apps/Dawn/Sources/Brand.swift): everything a brand is.
4. [`scripts/check-layering.py`](scripts/check-layering.py): the boundaries, as code.

```
Apps/            one folder per brand (+ shared scene delegate, hosted tests)
Packages/        Core · Adapters · Presentation · Features · AppShell
Project.swift    Tuist: one app and one hosted test target per brand
Tuist/           brand list and project helpers
scripts/         test runner, bump-shared.sh, boundary checks
docs/            architecture, comparison, adding a brand, ADRs, trackers
```

## Status

All planned features (F0–F9) are built; see [`docs/FeatureTracker.md`](docs/FeatureTracker.md). Out of scope by design: widgets, Apple Watch, Firebase. Still open: device-only checks (a Watch night in Apple Health, a melody over a sleeping phone, first-install permission prompts) and Learn URLs for the brands that have the tab.

`AGENTS.md` (mirrored as `CLAUDE.md`) holds the working rules for people and AI agents.
