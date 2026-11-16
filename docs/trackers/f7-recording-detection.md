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
| F7-T3 | Capture adapter: tap off the main thread, levels, FFT score, sound classifier, event clip writer and compressor | Adapter | Backlog | F7-T1 | SleepAudio | Realtime tap isolated in one allow-listed file; simulator tests on generated audio |
| F7-T4 | Recording actor: samples into the shared `DetectionEngine`, `RecordingDraft`, `AsyncStream<LiveSnapshot>` | Domain / Adapter | Backlog | F7-T3 | SleepDomain, SleepAudio | Characterization tests ported from SleepGuard's tracker tests |
| F7-T5 | `RecordingFeature`: prestart, countdown, bedside clock, summary | UI | Backlog | F7-T4 | RecordingFeature | Matches SleepGuard |
| F7-T6 | `RecordingFlow`, `CommitSession`, discard; full-screen modal owned by `AppCoordinator` | Shell | Backlog | F7-T5 | AppShell, SleepDomain | Works with any tab set; flow tests |
| F7-T7 | Checkpointing and `RecoverInterruptedSession` at launch; low-battery save | Domain / Shell | Backlog | F7-T6 | SleepDomain, SleepPersistence, AppShell | Kill the app mid-night; the night is offered at next launch |

## Notes

- The detection state machine and its goldens are already shared (`SleepCore`). Do not copy them.
- Needs a real device for a meaningful end-to-end check; say so in the session log when only the simulator was used.
- 2026-11-16: decided with the user: the per-sample detection rules go to the shared repo and SleepGuard uses them (T1, T2); F7 covers the core night only. Left for F8: Snore Interrupter and melodies, start delay, sensitivity setting UI, storage limits, raw sample log.
