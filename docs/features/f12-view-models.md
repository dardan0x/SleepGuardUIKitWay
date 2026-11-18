# F12 — View models and factories

Every screen now has three parts:
- **A view model** decides: what the screen shows, what a tap means, where the user goes next, and which alert is due.
- **A UIKit controller** draws it.
- **The flow's factory** builds both, from the container.

Decided with the owner on 2026-11-18 (ADR 0008).

## The layers

| Layer | Holds | Imports |
|---|---|---|
| `…ViewModel` | `State`, the draft or selection, `Alert?`, intents (`async` for work), `Routes` | Foundation, Observation, `SleepDomain`, `SleepCore` (checked) |
| `…ViewController` | UIKit structure, hosted shared views, tasks it owns, alert text | UIKit, SwiftUI, ScreenKit, the content kit |
| `…Factory` (AppShell) | Container → `Dependencies` → view model → controller | everything |

## View models

| Screen | View model | Decides |
|---|---|---|
| History | `HistoryViewModel` | Empty or months; confirm, then delete each night of a day; report a failure |
| Night detail | `SessionDetailViewModel` | Load, error, retry, cancellation; the filter; play, show all, share only with a clip, stages info |
| Player | `PlayerViewModel` (was `ClipPlaybackModel`) | Playlist, playback, waveform |
| Onboarding | `OnboardingViewModel` | Page, Skip/Back, permissions, the 0.8 s pause, finish |
| Dashboard | `StatisticsViewModel` | Dashboard or empty, profile prompt, the latest night's stages |
| Trends, Calendar, Last 7 Nights | `NightsViewModel` | The nights live, the calendar's month and day, opening a night |
| Settings | `SettingsViewModel` | Preferences, permissions, writes in order, confirmations, cleanup report |
| Profile editor | `ProfileEditorViewModel` | Draft, save or close |
| Prestart | `RecordingPrestartViewModel` | Preferences, delay, interrupter choice, microphone and charging checks |
| Countdown | `RecordingCountdownViewModel` | Seconds left, start once at zero |
| Bedside clock | `BedsideClockViewModel` over `LiveRecordingModel` | Early stop, start failure, stop and route |
| Summary | `SessionSummaryViewModel` | Too short to save; save or discard |
| Record melody | `RecordMelodyViewModel` | Record, the limit, playback, save as "My Sound N" |
| Snore Interrupter, Melody picker | `SnoreInterrupterViewModel`, `MelodyPickerViewModel` | The draft choice; selection, preview, recordings |
| Events sheet | `EventsSheetViewModel` | The rows; Play plays a row's episode |
| Stages sheet | `SleepStagesInfoViewModel` | The breakdown; Close |
| Briefing | `BriefingViewModel` | The briefing; a survey answer or Close |
| Learn | `LearnViewModel` | The brand's page, or none |

The last four only show values. They have view models anyway (the owner's choice), so no controller holds data or calls a route; `check-layering.py` fails a screen without one.

## Files

| File | Purpose |
|---|---|
| `Packages/Features/Sources/*Feature/*ViewModel.swift` | The view models |
| `Packages/Features/Sources/*Feature/*ViewController.swift` | Controllers that draw them |
| `Packages/Features/Tests/*` | View-model tests (`SettingsFeatureTests` is new) |
| `Packages/AppShell/Sources/AppShell/*/*Factory.swift`, `History/HistoryFactories.swift` | The factories (were composers); `BriefingFactory` is new (the sheet was built in `AppCoordinator`) |
| `Packages/Presentation/Sources/ScreenKit/ScreenController.swift` | `presentAlert(_:make:)` |
| `Packages/Core/Sources/SleepDomainTestSupport/FakeMelodyPorts.swift` | The fake recorder keeps its take at the limit, like the adapter |
| `scripts/check-layering.py` | View models import no UI; every screen declares a view model |
| `docs/adr/0008-view-models.md` | The decision |

## Edge cases

- A night detail cancelled mid-load stays loading and loads again on the next appearance; it never shows an error for that.
- Reaching the melody's time limit keeps the take (the fake used to lose it).
- A cancelled delete or load never sets an error.
- Settings' writes land in order, even when a Health answer arrives between them.
- The countdown starts the night once, even if the zero tick and Start now coincide.

## Limits

- One more type per screen: 19 view models for 21 screens (Trends, Calendar and Last 7 Nights share one).
- Flow tests reach routes through `controller.viewModel.routes`, so `routes` and `dependencies` are internal on view models.
