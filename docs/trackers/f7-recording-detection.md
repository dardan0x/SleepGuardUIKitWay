# F7 — Recording and detection

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P1 |
| **Milestone** | M3 |
| **Blocked By** | F2, F5 |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The user starts a night, the app listens and detects snoring and sleep talking, and on stop the night is summarised and saved. A night interrupted by a crash or low battery is recovered at next launch.

## Tasks

| ID | Task | Type | Status | Depends On | Module | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F7-T1 | Classifier rules and sensitivity thresholds as pure policies | Domain | Backlog | F2 | `SleepCore` or SleepDomain | Same verdicts as SleepGuard's `SnoreDetectorTests` and sensitivity tests |
| F7-T2 | Capture and analysis adapters (`AudioCapturePort`, sound analysis, clip writer) | Adapter | Backlog | F7-T1 | SleepAudio | Realtime tap isolated in one allow-listed file |
| F7-T3 | Recording actor: `RecordingDraft`, detection stream, `AsyncStream<LiveSnapshot>` | Domain / Adapter | Backlog | F7-T2 | SleepDomain, SleepAudio | Characterization tests ported from SleepGuard's tracker tests |
| F7-T4 | `RecordingFeature`: prestart, countdown, bedside clock, summary | UI | Backlog | F7-T3 | RecordingFeature | Matches the design |
| F7-T5 | `RecordingFlow`, `CommitSession`, discard; full-screen modal owned by `AppCoordinator` | Shell | Backlog | F7-T4 | AppShell, SleepDomain | Works with any tab set; flow tests |
| F7-T6 | Checkpointing and `RecoverInterruptedSession` at launch; low-battery save | Domain / Shell | Backlog | F7-T5 | SleepDomain, SleepPersistence, AppShell | Kill the app mid-night; the night is offered at next launch |

## Notes

- The detection state machine and its goldens are already shared (`SleepCore`). Do not copy them.
- Needs a real device for a meaningful end-to-end check; say so in the session log when only the simulator was used.
