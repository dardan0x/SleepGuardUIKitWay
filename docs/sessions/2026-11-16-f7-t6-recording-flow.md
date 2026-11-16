
### Completed
- F7-T6: the recording flow end to end in the shell: Start Recording → prestart → bedside clock → summary → saved or discarded.

### Technical Details
- `RecordingFlow` owns its own navigation controller, presented full screen by `AppCoordinator`; each step is `setRoot`, so a finished step can't be returned to. It doesn't depend on any tab (SleepGuard's summary needed its Statistics tab alive).
- `CommitSession` stores the night with its summary and refuses one under `Night.minimumSaveDuration` (the summary screen also checks, before asking).
- Discard removes the night's clips; nothing was saved, so nothing else to undo.
- `DeviceServices` keeps UIKit's app-wide state (idle timer, Settings URL, battery) in one allow-listed file; tests swap it.
- Info.plist gains the microphone text (brand name in it) and background audio; without them a night would stop at screen lock.
- Recording settings are SleepGuard's defaults (medium, sleep talking off) until Settings (F8).

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Core/Sources/SleepDomain/UseCases/CommitSession.swift` | New use case |
| `Packages/Core/Tests/SleepDomainTests/CommitSessionTests.swift` | 3 tests |
| `Packages/AppShell/Sources/AppShell/Recording/RecordingFlow.swift` | New: the flow |
| `Packages/AppShell/Sources/AppShell/Recording/RecordingComposer.swift` | New: screens, model, save-failed alert |
| `Packages/AppShell/Sources/AppShell/Recording/DeviceServices.swift` | New: screen on, Settings, charging |
| `Packages/AppShell/Sources/AppShell/Coordinators/AppCoordinator.swift` | `startRecording()` presents the flow |
| `Packages/AppShell/Sources/AppShell/Container+AppShell.swift` | `commitSession`, `makeAudioCapture`, `deviceServices` |
| `Packages/AppShell/Package.swift` | Depends on `RecordingFeature` |
| `Packages/AppShell/Tests/AppShellTests/RecordingFlowTests.swift` | 9 flow tests |
| `Apps/HostedTests/RecordingInAppTests.swift`, `Apps/HostedTests/BrandBootstrapTests.swift` | In-app presentation test; new registrations resolve |
| `Tuist/ProjectDescriptionHelpers/Target+Brand.swift` | Microphone text, background audio |
| `scripts/check-layering.py` | `RecordingFeature` for AppShell; `UIApplication.shared` allowed in `DeviceServices` |
| `docs/trackers/f7-recording-detection.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | T6 done |

### Build Status
- Every lane passes: Core (30), packages standalone (AppShell 37), in-app tests for the three brands (9 each). Layering, view size, format pass.
- On screen (simulator): the prestart full screen over the tabs, held in the hosted test and captured.
- Not checked: the bedside clock and summary on screen, and a night on a device (microphone, locked screen, background audio, clips).

### Next Session
- A short night on a device (Debug: 2 minutes is enough to save); then F7-T7, checkpoints and recovery.
