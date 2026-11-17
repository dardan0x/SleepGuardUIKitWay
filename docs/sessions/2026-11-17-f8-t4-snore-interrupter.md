
### Completed
- F8-T4: The Snore Interrupter, built content-first in one task (the owner's choice), with its sounds in the shared repo.

### Technical Details
- **Shared (0.24.0)**:
  - SleepCore: `SnoreInterrupterMode` (SleepGuard's raw values: `playDuration`, `loops`, `isOn`), `Melody` and its catalog (`Melody.builtIn`, `Melody.defaultID`, `Melody.resolve`, which falls back to the default for a deleted recording), `CustomMelodies` (10 s cap, ids from 100 never reused, `custom_<id>.m4a`, the "My Sound N" number), `[RecordingGap].adding` / `markingLastSnoringResumed`.
  - `SleepMelodies`: the 11 sound files, moved from SleepGuard's bundle.
  - Strings for the melody names (English-only in SleepGuard) and "My Sound %d".
  - Design kit rows and bedside pieces; content kit `PrestartOptions`, `SnoreInterrupterSettingsContent`, `MelodyPickerContent`, `RecordMelodyContent`.
- **Core**:
  - Ports `MelodyPlayer`, `MelodyStore`, `MelodyRecorder`; `AudioCapturePort.pause()` / `resume()`.
  - `SnoreInterrupter` (per night, main actor): plays when on, not muted and not already playing, with the microphone paused. Every way it stops (its length, the file's end, Stop, Mute, the night ending) resumes the microphone and yields `.melodyDidStop` straight into the engine's stream, so the gap is in order with the samples.
  - `RecordingSession` performs `.melodyRequested` (feedback `.melodyDidStart`), `.melodyStopRequested`, `.eventClipClosed` (the event keeps that clip when it ends after the melody), `.recordingGap` and `.snoringResumedAfterMelody`.
  - The snapshot carries `melodyPlaying`, and the raw log the real mode.
- **Adapters**:
  - `AVMelodyPlayer` plays in capture's `.playAndRecord` session; at night a haptic nudge every 2 s, supplied by the shell. The preview player is quieter (0.8) with no nudge.
  - `FileMelodyStore`: `Melodies/` under the storage root, with a JSON list.
  - `AVMelodyRecorder`: AAC mono, 10 s.
  - `EngineAudioCapture` pauses by stopping its engine and keeps the stream; route changes don't restart it while paused.
- **Screens and flow**:
  - The prestart's row (when the brand has the interrupter).
  - `SnoreInterrupterScreen`, `MelodyPickerScreen` (3 s preview, a second tap stops it) and `RecordMelodyScreen`, as stacked sheets from `RecordingFlow`. Save keeps the choice under SleepGuard's keys (`soothingMelodyMode`, `selectedMelodyID`).
  - The bedside's note (Mute for the night) and overlay (Mute, Stop).
- **Brand** (ADR 0006): `BrandConfiguration.snoreInterrupter: Bool`, a value because every brand links AVFoundation. Off in Lite, so no store, no row, and no interrupter at night.

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Core/Sources/SleepDomain/Ports/{SnoreInterrupterPorts,AudioCapturePort}.swift`, `Recording/{SnoreInterrupter,RecordingSession,RecordingDraft}.swift`, `Settings/AppPreferences.swift` | Ports, the interrupter, melody outputs, snapshot, preferences |
| `Packages/Core/Sources/SleepDomainTestSupport/{FakeMelodyPorts,FakeAudioCapture}.swift` | Fakes |
| `Packages/Core/Tests/SleepDomainTests/{SnoreInterrupterTests,RecordingSessionTests}.swift` | Interrupter rules; SleepGuard's melody cases |
| `Packages/Adapters/Sources/SleepAudio/{Interrupter/*,Capture/EngineAudioCapture,SleepAudio}.swift`, `Package.swift`, `Tests/SleepAudioTests/FileMelodyStoreTests.swift` | Player, store, recorder, pause/resume |
| `Packages/Adapters/Sources/SleepPersistence/Store/UserDefaultsPreferencesStore.swift` | Interrupter keys |
| `Packages/Features/Sources/RecordingFeature/{SnoreInterrupterScreens,RecordMelodyScreen,RecordingPrestartScreen,RecordingRoutes,BedsideClockScreen,LiveRecordingModel}.swift` | Screens, row, bedside, model |
| `Packages/AppShell/Sources/AppShell/{Brand/BrandComposition,Container+AppShell,Recording/RecordingComposer,Recording/RecordingFlow,Storage/StorageLocation}.swift`, `AppShellTestSupport/TestBrand.swift`, `Apps/*/Sources/Brand.swift` | Brand value, wiring, sheets |
| `Packages/AppShell/Tests/AppShellTests/{SnoreInterrupterFlowTests,HistoryFlowTests}.swift` | Flow tests; fakes in the test container |
| `scripts/check-layering.py`, `AGENTS.md`, `CLAUDE.md` | `SleepAudio` may import `SleepMelodies` |
| `docs/adr/0006-brand-capabilities.md`, `docs/architecture/brands.md`, trackers, Roadmap | Docs (`brands.md`'s old `Capabilities` plan replaced by ADR 0006's) |

### Build Status
- All lanes green on the local shared checkout: Core 60, Adapters 18, Presentation 13, Features 4, AppShell 59, hosted tests in all three brands (9 each); layering, view-size and hardcoded-string checks pass. Re-run on the 0.24.0 release (`TUIST_SHARED_RELEASE=1`): all green.
- SleepGuard's three melody cases give the same events and gaps here as in SleepGuard.

### Next Session
- Device check: a melody over a sleeping phone, the microphone back after it, a recording made and played. Then F8-T2, onboarding.

### Open Questions
- A clip closed for the melody whose event is then discarded stays on disk until the launch cleanup (`EnforceStorageLimits` removes files no night refers to). SleepGuard deletes it at once.
