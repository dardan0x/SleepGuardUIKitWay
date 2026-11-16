# F7 — Recording and detection

The user starts a night from Start Recording, the app listens through the night and detects snoring (and, when switched on, sleep talking), and on Stop the night is summarised for Save or Discard. A night interrupted by a crash, a kill or a dead battery is offered again at the next launch; at 2% battery the night is stopped and kept. The detection rules and their inputs are shared with SleepGuard, and so are the screens' pieces. The core night only: the Snore Interrupter, start delay, sensitivity setting, storage limits and raw sample log are F8.

## Files

| File | Purpose |
|------|---------|
| `../SleepGuardShared/Sources/SleepCore/Detection/SnoreClassifier.swift` | Per-sample snore / speech rules, sensitivity presets (0.14.0) |
| `../SleepGuardShared/Sources/SleepCore/Audio/*` | `AudioLevels`, `SpectralFeatures`, `SoundClassLabels` (0.15.0) |
| `../SleepGuardShared/Sources/SleepGuardDesignKit/Components/RecordingViews.swift` | Prestart, bedside and summary pieces; `NightTimeline(night:)` (0.16.0) |
| `../SleepGuardShared/Sources/SleepCore/Night/Night.swift` | `Night.minimumSaveDuration` (0.16.0) |
| `Packages/Core/Sources/SleepDomain/Ports/AudioCapturePort.swift` | Capture port, `CaptureSample` |
| `Packages/Core/Sources/SleepDomain/Ports/RecordingCheckpointStore.swift` | Checkpoint port |
| `Packages/Core/Sources/SleepDomain/Recording/RecordingSession.swift` | The recording actor: samples → shared `DetectionEngine` → draft; checkpoints |
| `Packages/Core/Sources/SleepDomain/Recording/RecordingDraft.swift` | `RecordingDraft`, `LiveSnapshot` |
| `Packages/Core/Sources/SleepDomain/UseCases/{CommitSession,DiscardRecording,RecoverInterruptedSession}.swift` | Save, discard, recover |
| `Packages/Core/Sources/SleepDomainTestSupport/{FakeAudioCapture,FakeRecordingCheckpointStore}.swift` | Fakes |
| `Packages/Adapters/Sources/SleepAudio/Capture/*` | AVAudioEngine capture, per-buffer processing (the one allow-listed lock), sound classifier, HE-AAC compressor |
| `Packages/Adapters/Sources/SleepPersistence/Store/FileCheckpointStore.swift` | Checkpoint as one JSON file, atomic writes |
| `Packages/Features/Sources/RecordingFeature/*` | Prestart, bedside clock (`LiveRecordingModel`), summary |
| `Packages/AppShell/Sources/AppShell/Recording/*` | `RecordingFlow`, `RecordingComposer`, `DeviceServices` |
| `Packages/AppShell/Sources/AppShell/Coordinators/AppCoordinator.swift` | Presents the flow; offers an interrupted night at launch |
| `Tuist/ProjectDescriptionHelpers/Target+Brand.swift` | Microphone text, background audio |
| SleepGuard: detectors, tracker, tap processor, FFT analyzer, sound classifier, recording views | Use the shared rules, inputs and pieces |

## Routes

| From | Route | To | How |
|------|-------|----|-----|
| Statistics (empty or loaded) | `startRecording` | Prestart | Full-screen modal from `AppCoordinator` |
| Launch | interrupted night found | Summary | Full-screen modal from `AppCoordinator` |
| Prestart | Start (microphone, charger checked) | Bedside clock | Replaces the prestart |
| Prestart | Cancel | Tabs | Dismiss |
| Prestart | microphone alert → Open Settings | Settings app | `DeviceServices.openSettings` |
| Bedside clock | Stop (≥ minimum) or 2% battery | Summary | Replaces the clock |
| Bedside clock | Stop early → Stop Anyway, or a failed start | Tabs | Clips and checkpoint removed; dismiss |
| Summary | Save | Tabs | `CommitSession`; dismiss. Failure: alert, stays |
| Summary | Discard | Tabs | `DiscardRecording`; dismiss |

## State

| State | Where | Lifetime |
|-------|-------|----------|
| Night in progress (events, levels) | `RecordingDraft` in `RecordingSession` (actor) | Start to stop |
| Phase, latest snapshot | `LiveRecordingModel` (`@Observable`, owned by `RecordingFlow`) | Start to summary |
| Detection state | Shared `DetectionEngine` (actor) | The night |
| Open clip, engine, audio session | `EngineAudioCapture` / `CaptureProcessor` | Listening |
| Checkpoint | `Recording.json` in the brand's storage root | Recording until saved or discarded |
| Screen kept on | `DeviceServices.keepScreenOn` | Bedside clock |

## Edge cases

- **Interruption (call) or route change:** listening pauses and resumes on its own; an open clip ends if the input format changes.
- **Stop before the minimum (2 min Debug, 30 min Release):** asks; Stop Anyway discards. The summary also refuses to save a short night.
- **Event that starts as the microphone stops:** kept, without a clip (no audio left to write).
- **Compression fails:** the raw `.caf` is kept and plays.
- **Crash, kill or dead battery:** the checkpoint (after each event, each clip, every 2 minutes, and at stop) comes back at launch as the summary. A checkpoint without events is cleared silently, as SleepGuard.
- **Battery at 2%:** checked every 30 s while recording; the night stops as a low-battery night (banner on the summary).
- **Save fails:** alert; the checkpoint stays, so the night isn't lost.
- **No microphone permission:** alert with Open Settings.

## Tasks completed

F7-T1 detection rules in `SleepCore` · F7-T2 SleepGuard's detectors on them · F7-T3 capture inputs shared, capture adapter · F7-T4 recording actor · F7-T5 recording screens (kit pieces shared) · F7-T6 recording flow, commit, discard · F7-T7 checkpoints, launch recovery, low-battery stop.

## Open

- A night on a device: microphone, locked screen with background audio, clips, a real interruption. Only the simulator was used.
- Clip of an event open at a crash stays on disk (SleepGuard tracks pending files to clean these; not ported).
