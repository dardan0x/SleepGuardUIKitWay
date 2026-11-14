# F5 — Clip playback

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | Backlog |
| **Priority** | P1 |
| **Milestone** | M2 |
| **Blocked By** | F3 |
| **Started** | — |
| **Completed** | — |
| **Feature Doc** | — |

## Summary

The user plays the recorded clips of a night in sequence from the session detail, with seek and next/previous.

## Tasks

| ID | Task | Type | Status | Depends On | Module | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F5-T1 | `ClipPlaybackPort` and an `@Observable` playback state owner | Domain / UI | Backlog | F3 | SleepDomain, SessionDetailFeature | State owner tested with a fake port |
| F5-T2 | AVAudioEngine adapter | Adapter | Backlog | F5-T1 | SleepAudio | Plays a fixture clip; interruption handled |
| F5-T3 | Player sheet presented by the flow; state owner built by the composer | Shell | Backlog | F5-T1, F5-T2 | AppShell | Resources released when the sheet closes |

## Notes

- This is the one place an `@Observable` state owner is justified: it owns an imperative audio resource.
- Needs clips to play: seed fixture audio with the sample nights (F2-T5) until recording exists.
