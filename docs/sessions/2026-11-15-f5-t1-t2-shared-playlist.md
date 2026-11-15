
### Completed
- F5 planned in detail (5 tasks). The pure playback logic goes to the shared repo (decided with the user).
- F5-T1: `ClipPlaylist`, `PlaybackGain`, `PlaybackEnhancement` in `SleepCore` (for 0.10.0), 9 tests.
- F5-T2: SleepGuard's `ClipPlaybackController` uses them (SleepGuard branch `feature/shared/f5-t2-shared-playlist`).

### Technical Details
- The playlist is a value: the engine reports (a clip finished) and the playlist decides (play the next one, or stop at the start).
- Out of F5: waveform and advanced views, legacy nights, sharing, persisting the enhanced-audio choice.

### Build Status
- Shared 0.10.0: SleepCore 109, kit 7, strings 2. Both apps bumped and tested against the release (SleepGuard 8 suites and release build; this repo's lanes and in-app tests for all three brands).
- SleepGuard's controller has no tests: it needs a listen.

### Next Session
- F5-T3: `ClipPlayer` port and the playback state owner.
