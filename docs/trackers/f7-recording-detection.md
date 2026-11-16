# F7 — Recording and detection

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | In Progress |
| **Priority** | P1 |
| **Milestone** | M3 |
| **Blocked By** | F2, F5 |
| **Started** | 2026-11-16 |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The user starts a night, the app listens and detects snoring and sleep talking, and on stop the night is summarised and saved. A night interrupted by a crash or low battery is recovered at next launch.

## Tasks

| ID | Task | Type | Status | Depends On | Module | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F7-T1 | Per-sample detection rules in `SleepCore` (shared 0.14.0): `SnoreClassifier` + sensitivity presets, `SpeechClassifier`, `DetectionSensitivity` | Domain | Done | F2 | Shared repo | SleepGuard's `SnoreDetectorTests` / `DetectionSensitivityTests` cases pass |
| F7-T2 | SleepGuard's detectors and tracker use them | Refactor | Done | F7-T1 | SleepGuard | Its tests and the replay goldens pass unchanged |
| F7-T3 | Capture adapter: tap off the main thread, levels, FFT score, sound classifier, event clip writer and compressor | Adapter | Done | F7-T1 | SleepAudio | Realtime tap isolated in one allow-listed file; simulator tests on generated audio |
| F7-T4 | Recording actor: samples into the shared `DetectionEngine`, `RecordingDraft`, `AsyncStream<LiveSnapshot>` | Domain / Adapter | Done | F7-T3 | SleepDomain, SleepAudio | Characterization tests ported from SleepGuard's tracker tests |
| F7-T5 | `RecordingFeature`: prestart, bedside clock, summary (countdown → F8, with the start delay) | UI | Done | F7-T4 | RecordingFeature | Matches SleepGuard |
| F7-T6 | `RecordingFlow`, `CommitSession`, discard; full-screen modal owned by `AppCoordinator` | Shell | Backlog | F7-T5 | AppShell, SleepDomain | Works with any tab set; flow tests |
| F7-T7 | Checkpointing and `RecoverInterruptedSession` at launch; low-battery save | Domain / Shell | Backlog | F7-T6 | SleepDomain, SleepPersistence, AppShell | Kill the app mid-night; the night is offered at next launch |

## Notes

- The detection state machine and its goldens are already shared (`SleepCore`). Do not copy them.
- Needs a real device for a meaningful end-to-end check; say so in the session log when only the simulator was used.
- 2026-11-16: decided with the user: the per-sample detection rules go to the shared repo and SleepGuard uses them (T1, T2); F7 covers the core night only. Left for F8: Snore Interrupter and melodies, start delay, sensitivity setting UI, storage limits, raw sample log.

## Task Details

### F7-T5 — Recording screens (done 2026-11-16)
**T5a — shared (0.16.0)**
- [x] Kit `RecordingViews.swift`: `PrestartHeader`, `PrestartTipsCard`, `BedsideEventsBadge`, `BedsideClockFace`, `BedsideRecordingStatus`, `BedsideSnoreStatus`, `SessionSummaryHeader`, `SessionSummaryActions`; `NightTimeline(night:)`; `RecordingGallery` and render tests in both themes (one fix on the way: the prestart title can wrap)
- [x] `Night.minimumSaveDuration` in SleepCore (120 s Debug, 30 min Release), from SleepGuard's `SleepSession`
- [x] SleepGuard (branch `feature/shared/f7-t5-recording-components`): its prestart, bedside and summary views draw with the kit; 9 view files deleted (approved); `SleepSession.minimumSaveDuration` forwards to SleepCore

**T5b — `RecordingFeature`**
- [x] `RecordingPrestartScreen`: header, tips, Start (microphone, then charger: alerts for each, as SleepGuard), Cancel. No delay or Snore Interrupter rows (F8)
- [x] `LiveRecordingModel` (state owner: owns the `RecordingSession`): phase, latest snapshot, `run()` from `.task`, `isTooShort(at:)`, `stop(at:) -> Night`
- [x] `BedsideClockScreen`: badge, clock, recording status and meter, snore tier, Stop (with SleepGuard's early-stop alert → discard); a failed start alerts and leaves. Ticks with `TimelineView`, not a sleep loop
- [x] `SessionSummaryScreen`: header from the night's summary, gap and low-battery banners, timeline, Save (too-short alert) / Discard
- [x] Routes and dependencies only as closures and values: the shell (T6) supplies permission, charging, settings, idle timer, and commits
- [x] 4 tests (`LiveRecordingModelTests`), run 3× clean against the local shared checkout
- Not checked on screen yet: the shell shows these from T6. The renders of every kit piece were checked in both themes.

### F7-T4 — Recording actor (done 2026-11-16)
- [x] `RecordingSession` (SleepDomain, actor): `start()` starts the capture and the shared `DetectionEngine`, returns `AsyncStream<LiveSnapshot>` (5 Hz by sample time, newest only); `stop(at:)` stops the capture, drains the queued samples, finalizes, waits for compressions and returns the `RecordingDraft`
- [x] Per sample: `SnoreClassifier.preset(sensitivity)` on the peak level (spectral score left out of the verdict, as in SleepGuard), `SpeechClassifier`, then `.sample` into the engine; engine settings from the sensitivity (`minEventDuration`, `highConfidenceGate`) and the sleep-talking flag
- [x] Outputs performed in order: clip start / close / discard through the port, snore and sleep-talking events into the draft. Compression is a task beside the engine; the event points at the `.m4a` when done, at the raw `.caf` if compression failed
- [x] `RecordingDraft` (value: id, start, events, gaps, levels) → `night(end:endReason:)`; `LiveSnapshot`
- [x] Port change from T3 (nothing used it yet): `finishClip()` split into `closeClip()` (immediate, in event order) and `compressClip(named:)`; `stop()` leaves an open clip for the final flush instead of deleting it, so the night's last event keeps its audio
- [x] 17 tests (macOS): SleepGuard's `DetectionCharacterizationTests` event and sleep-talking cases with their samples and expected lines unchanged (melody cases wait for F8), clips (kept, failed compression, discarded), draft → night, samples drained at stop, snapshot rate, start failure
- Differs from SleepGuard on purpose: the session peak level is the loudest sample (SleepGuard's `peakDB` starts at 0 and never rises, since dBFS is negative); samples come per buffer instead of a 20 Hz loop (the rules are in time, so the rate doesn't matter)
- Not yet: container registration and the flow (T6), checkpoints (T7), melody outputs (F8)

### F7-T3 — Capture (done 2026-11-16)
**T3a — detection inputs shared (done 2026-11-16; shared 0.15.0)**
- [x] `SleepCore/Audio`: `AudioLevels` (RMS / peak dBFS), `SpectralFeatures` (from a magnitude spectrum: low-band ratio, centroid, dominant frequency, snore score; spectrum bars), `SoundClassLabels` (snore and speech classes → confidences); 12 tests, the FFT ones SleepGuard's `FFTAnalyzerTests` on a plain DFT of the same signals
- [x] SleepGuard's `TapProcessor`, `FFTAnalyzer`, `SoundAnalysisDetector` use them (branch `feature/shared/f7-t3-shared-capture-rules`); its tests pass unchanged

**T3b — capture adapter (done 2026-11-16)**
- [x] `AudioCapturePort` (SleepDomain, main-actor): `start()` returns an `AsyncStream<CaptureSample>` (time, RMS / peak dB, spectral score, snore / speech confidence), one per buffer; `startClip(id:)`, `finishClip()` (→ file name), `discardClip()`, `stop()`. `FakeAudioCapture` in test support
- [x] `EngineAudioCapture` (SleepAudio): direct input tap, no output path; `.playAndRecord` + `.measurement` (no automatic gain, full band); a new engine at every start; resumes after an interruption that allows it, an engine configuration change, or a device arriving / leaving
- [x] `CaptureProcessor`: the tap's work behind one lock (levels via `AudioLevels`, vDSP transform → `SpectralFeatures`, SoundAnalysis frames, clip writes); the one escape hatch, now matched by the layering check (`uncheckedState`, `withLockUnchecked`) and allow-listed
- [x] `SoundClassifier`: SoundAnalysis observer, confidences via `SoundClassLabels` behind a checked lock
- [x] `ClipCompressor`: mono HE-AAC ~12 kbps (AAC-LC 24 kbps fallback), rate from the codec's list, as SleepGuard; written as one synchronous read → convert → encode loop with `AVAudioFile` / `AVAudioConverter` instead of an asset writer on a dispatch queue (no queue, no `Sendable` warnings). A failed compression keeps the raw `.caf`, which still plays
- [x] 7 simulator tests on generated audio: levels, silence, spectral score, classifier attached, clip holds only the buffers written while open, compression (size and length), clip needs listening
- Not checked: the engine on a microphone. The simulator's input can't be driven from a test; a device check is due with T5 (first screen that starts it). Not ported: the warm-up engine for a delayed start (F8), the melody pause / resume (F8), `didBecomeActive` resume (SleepAudio doesn't import UIKit; add it in the shell if a device night shows the need)
