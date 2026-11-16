# F5 — Clip playback

Tapping Play on an event (in a night's detail or the events sheet) opens a player sheet that plays the event's clips: a snoring row plays its whole episode in order. The player shows the event, a seek bar across all clips, back 15 s / play / forward 15 s, an enhanced-audio switch, and the clips to pick from. Clips play one after another; closing the sheet releases the audio engine. The playback rules are shared with SleepGuard.

## Files

| File | Purpose |
|------|---------|
| `../SleepGuardShared/Sources/SleepCore/Playback/*` | `ClipPlaylist`, `PlaybackGain`, `PlaybackEnhancement` (0.10.0) |
| `../SleepGuardShared/Sources/SleepGuardDesignKit/Components/PlayerViews.swift` | Player components and `EventIntensityLegend` (0.11.0) |
| `Packages/Core/Sources/SleepDomain/Ports/ClipPlayer.swift` | The player port |
| `Packages/Core/Sources/SleepDomain/Ports/SessionFileStore.swift` | `url(forFileNamed:)` |
| `Packages/Core/Sources/SleepDomainTestSupport/FakeClipPlayer.swift` | Fake player |
| `Packages/Adapters/Sources/SleepAudio/EngineClipPlayer.swift` | AVAudioEngine player (SleepGuard's chain) |
| `Packages/Adapters/Sources/SleepAudio/SampleClips.swift` | Debug: generated snore-like clips |
| `Packages/Features/Sources/SessionDetailFeature/ClipPlaybackModel.swift` | The state owner |
| `Packages/Features/Sources/SessionDetailFeature/PlayerScreen.swift` | The player sheet's content |
| `Packages/Features/Sources/SessionDetailFeature/{SessionDetailScreen,EventsSheetScreen,DetailEvents}.swift` | Play routes; row → clips |
| `Packages/AppShell/Sources/AppShell/History/{NightDetailNavigation,HistoryComposers}.swift` | Present the player; build it |
| `Packages/AppShell/Sources/AppShell/Container+AppShell.swift` | `makeClipPlayer` |
| `Packages/Presentation/Sources/ScreenKit/Navigator.swift` | `SheetDetent.height` |
| `Packages/AppShell/Sources/AppShell/Debug/SampleNights.swift` | Sample clips for snoring events |
| `Apps/HostedTests/PlayerInAppTests.swift` | The player in the running app |
| SleepGuard: `Packages/Recordings/Sources/Helpers/ClipPlaybackController.swift` | Uses the shared playback rules |

## Routes

| From | Route | To | How |
|------|-------|----|-----|
| Night detail row | `playEvents(events, start)` | Player | Sheet, 580 pt and large |
| Events sheet card | `playEvents(events, start)` | Player | Sheet over the events sheet |
| Player | close bar button | Back | Dismiss (releases the engine) |

## State

| State | Where | Lifetime |
|-------|-------|----------|
| Playlist, playing, position, enhanced | `ClipPlaybackModel` (`@Observable`, built by the composer) | The player sheet |
| Audio engine, loaded file | `EngineClipPlayer` | Until `close()` |

## Edge cases

- **Missing clip file:** "Audio Unavailable" card; nothing plays.
- **File shorter than its event:** the clip plays to the file's end.
- **Last clip finishes:** back to the first clip, stopped.
- **Seek past the end / to a clip's end while playing:** parks at the end / moves to the next clip, as SleepGuard.
- **Interruption (call, another app):** playback stops at its place.
- **Enhanced audio off:** bit-exact playback.

## Tasks completed

F5-T1 playback rules in `SleepCore` · F5-T2 SleepGuard's controller on them · F5-T3 port and state owner · F5-T4 AVAudioEngine adapter · F5-T5 player sheet and sample clips.
