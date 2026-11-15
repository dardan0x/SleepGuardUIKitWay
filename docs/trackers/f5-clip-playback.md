# F5 — Clip playback

> Updated by the AI after every task in this feature. Task details are expanded when the feature starts.

| Field | Value |
|-------|-------|
| **Status** | Done |
| **Priority** | P1 |
| **Milestone** | M2 |
| **Blocked By** | F3 |
| **Started** | 2026-11-15 |
| **Completed** | 2026-11-15 |
| **Feature Doc** | [f5-clip-playback.md](../features/f5-clip-playback.md) |

## Summary

The user plays the recorded clips of a night in sequence from the session detail, with seek and next/previous.

## Tasks

| ID | Task | Type | Status | Depends On | Module | Acceptance (short) |
|----|------|------|--------|------------|--------|--------------------|
| F5-T1 | Playback rules in `SleepCore` (shared 0.10.0): `ClipPlaylist` (joined timeline, seek, select, after-clip), `PlaybackGain`, `PlaybackEnhancement` | Domain | Done | F3 | Shared repo | Same behaviour as SleepGuard's controller; tested |
| F5-T2 | SleepGuard's `ClipPlaybackController` uses them; its AVAudioEngine code unchanged | Refactor | Done | F5-T1 | SleepGuard | Tests pass; play, seek, next/previous, auto-advance checked by ear |
| F5-T3 | `ClipPlayer` port, clip URLs from `SessionFileStore`, `@Observable` playback state owner | Domain / UI | Done | F5-T1 | SleepDomain, SessionDetailFeature | State owner tested with a fake player |
| F5-T4 | AVAudioEngine adapter (filter chain, gain, interruption, session) | Adapter | Done | F5-T3 | SleepAudio | Plays a generated clip; finish and interruption reported |
| F5-T5 | Player sheet, Play on rows and cards, presented by the flow; Debug sample clips | UI / Shell | Done | F5-T3, F5-T4 | SessionDetailFeature, AppShell | Engine released when the sheet closes; heard on the simulator |

## Notes

- This is the one place an `@Observable` state owner is justified: it owns an imperative audio resource.
- Needs clips to play: seed fixture audio with the sample nights (F2-T5) until recording exists.
- 2026-11-15: the pure playback logic goes to the shared repo (decided with the user), and SleepGuard's controller uses it (F5-T2).
- Not in F5: waveform and the advanced views (spectrum, stats), legacy nights without clips (UIKitWay has none), sharing a clip, persisting the enhanced-audio choice (Settings, F8; on by default).

## Task Details

### F5-T1 — Playback rules in the shared repo (done 2026-11-15; shared 0.10.0)
- [x] `SleepCore/Playback`: `ClipPlaylist` (clips from events, current clip and offset, joined timeline and progress, select, seek across and within clips, `clipFinished()` → play next or stop at the start), `PlaybackGain.boostDB(peak:)`, `PlaybackEnhancement` (80 Hz, 1.5 kHz)
- [x] 9 tests, written from SleepGuard's controller behaviour (it has no tests of its own)

### F5-T2 — SleepGuard uses them (done 2026-11-15; SleepGuard branch `feature/shared/f5-t2-shared-playlist`)
- [x] `ClipPlaybackController` keeps its public API and its engine code; its rules come from the shared types
- [x] SleepGuard's suites pass; app builds
- [ ] Listen in SleepGuard (user): play, pause, seek across clips, next/previous, auto-advance, enhanced on/off

### F5-T3 — Player port and playback state owner (done 2026-11-15)
- [x] `ClipPlayer` port (main-actor): load a file (its length), play from an offset for a duration with a finish callback, pause, position, enhanced on/off, interruption callback, stop
- [x] `SessionFileStore.url(forFileNamed:)`: the clip's file, `nil` when missing or not a plain name; tested
- [x] `FakeClipPlayer` in `SleepDomainTestSupport` (records calls; a test finishes, interrupts, moves time); `FakeSessionFileStore` serves given URLs
- [x] `ClipPlaybackModel` (`@Observable` state owner in `SessionDetailFeature`): SleepGuard's controller behaviour on `ClipPlaylist` and the port: starting clip, a clip plays for the shorter of its event and its file, auto-advance then stop at the start, pause/resume from the player's position, seek across and within clips (keeps playing), past-the-end parking, missing files, interruptions, enhanced toggle, close releases the player; progress polled every 0.1 s
- [x] 13 tests against the fake
- Note: seeking to a clip's end while playing moves to the next clip (nothing left to play), as SleepGuard does.

### F5-T4 — AVAudioEngine adapter (done 2026-11-15)
- [x] `EngineClipPlayer` (internal, `SleepAudio.makeClipPlayer()`): player → 2-band EQ → mixer, reconnected only when the format changes; band-pass from `PlaybackEnhancement`, per-file boost from `PlaybackGain` (bypassed when enhanced audio is off)
- [x] Plays a span with `.dataPlayedBack` (the end isn't cut), a token drops completions of paused or replaced spans; position from the start time; `.playback` session; interruptions reported once while playing; `stop()` releases engine, file and observer
- [x] 5 tests on the simulator with generated tones: length and boost, plays a span to its end, pause keeps the position and never finishes, interruption, silent clip gets no boost
- Same chain and numbers as SleepGuard's controller.

### F5-T5 — Player sheet (done 2026-11-15; shared 0.11.0)
- [x] Kit (shared 0.11.0): `PlayerHeader`, `PlayerProgress` (seek bar), `PlayerControls` (back 15 s, play/pause, forward 15 s), `PlayerEventRow`, `EnhancedAudioToggle`, `NoAudioCard`, `EventIntensityLegend`; player gallery rendered in two themes
- [x] `PlayerScreen` on `ClipPlaybackModel`: starts on appear, releases the player on disappear; no-audio card when the clip's file is missing
- [x] Play on detail rows and events-sheet cards: a snoring row plays its episode, anything else alone (`DetailEventRow.playback(in:)`, SleepCore's rule); `SessionDetailRoutes.playEvents`; "Show all" passes the night's events
- [x] `NightDetailNavigation` presents the player (title by kind of event, close button) at 580 pt and large, over the events sheet when it's open; `.height` sheet detent in ScreenKit; `makeClipPlayer` in the container (a main-actor maker)
- [x] Debug: sample snoring events have clips; seeding writes snore-like AAC clips (at most 15 s, so longer events show the "file shorter than the event" path) off the main actor before saving the nights
- [x] Tests: flow (Play presents the player, title, close dismisses), row playback rule, sheet height; in-app per brand on fresh installs: the player plays, advances to the episode's next clip once the first is heard, stops on close
- [x] Seen on the simulator: the player over a night's detail, playing (SleepGuard)
- Seen once (2026-11-15, Lite, on the 0.11.0 release run): `debugLaunchHasSampleNights` and the player test both timed out waiting for the store's nights; the rerun passed (8/8). Cause unknown; watch for it.
- Fixed on the way: `debugLaunchHasSampleNights` took the first update of the store; on a fresh install that's one night. It now waits for all 14.
- Differences from SleepGuard: a seek bar instead of the waveform (waveform out of F5); "Event 1 / 3" (SleepGuard hardcodes "of"); loudness in the event list from the localised labels (SleepGuard prints the raw value); enhanced audio isn't remembered yet (Settings, F8).
