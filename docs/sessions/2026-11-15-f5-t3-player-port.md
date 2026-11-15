
### Completed
- F5-T3: `ClipPlayer` port, `SessionFileStore.url(forFileNamed:)`, `FakeClipPlayer`, and `ClipPlaybackModel`, the state owner that plays a night's clips.

### Technical Details
- Split: SleepCore's `ClipPlaylist` decides what plays; the port makes it heard; the state owner keeps them in step. The engine (F5-T4) only loads, plays a span, pauses, and reports.
- `ClipPlaybackModel` is `@Observable` because it owns the player (the rule's exception); its collaborators come through `init`, so tests pass fakes.
- Progress: a task polls the player every 0.1 s while playing and ends with the model.

### Build Status
- See handover: package lanes, app build, checks.

### Next Session
- F5-T4: AVAudioEngine adapter in `SleepAudio`.
