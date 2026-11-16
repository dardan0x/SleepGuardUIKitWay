
### Completed
- F7-T4: `RecordingSession`, the recording actor: capture samples → shared `DetectionEngine` → `RecordingDraft`, with 5 Hz `LiveSnapshot`s for the screen.

### Technical Details
- One sender into the engine's ordered stream (ADR 0003). Per sample: `SnoreClassifier.preset(sensitivity)` on the peak level (spectral score out of the verdict, as in SleepGuard), `SpeechClassifier`, then `.sample`. Outputs come back to the actor and are performed in order.
- Clip compression is a task beside the engine, so a long clip never stalls detection; the event's `clipFileName` moves from `.caf` to `.m4a` when it finishes.
- `stop(at:)`: capture stops → queued samples drained → finalize → engine drained → compressions awaited → draft returned. For that the port changed (nothing used it yet): `finishClip()` became `closeClip()` + `compressClip(named:)`, and `stop()` no longer deletes an open clip, so the last event of the night keeps its audio.
- Deliberate differences from SleepGuard: the session peak is the loudest sample (SleepGuard's stays 0: it starts at 0 and dBFS is negative); samples per buffer, not a 20 Hz loop (rules are in time).

### Files Changed
| File | What Changed |
|------|--------------|
| `Packages/Core/Sources/SleepDomain/Recording/RecordingSession.swift` | New: the actor |
| `Packages/Core/Sources/SleepDomain/Recording/RecordingDraft.swift` | New: `RecordingDraft`, `LiveSnapshot` |
| `Packages/Core/Sources/SleepDomain/Ports/AudioCapturePort.swift` | `closeClip`, `compressClip(named:)`; `stop` keeps an open clip |
| `Packages/Core/Sources/SleepDomainTestSupport/FakeAudioCapture.swift` | Follows the port |
| `Packages/Adapters/Sources/SleepAudio/Capture/EngineAudioCapture.swift` | Follows the port; `start` discards a leftover clip |
| `Packages/Core/Tests/SleepDomainTests/RecordingSessionTests.swift` | New: 17 tests, SleepGuard's characterization cases among them |
| `AGENTS.md`, `CLAUDE.md` | `RecordingSession` is the engine's one sender |
| `docs/trackers/f7-recording-detection.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | T4 done |

### Build Status
- All lanes pass: Core on macOS (27, the recording tests stable over 8 repeated runs), every package standalone, in-app tests for the three brands. Layering and format pass, no warnings.

### Next Session
- F7-T5: `RecordingFeature` screens; first device check of the capture.

### Open Questions
- SleepGuard's session `peakDB` is always 0 (see above). Fix there, or leave it: nothing in SleepGuard shows it today as far as I've seen.
