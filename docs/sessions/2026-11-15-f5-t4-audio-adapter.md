
### Completed
- F5-T4: `EngineClipPlayer`, the `ClipPlayer` over AVAudioEngine, in `SleepAudio`, with 5 simulator tests on generated tones.

### Technical Details
- Same chain as SleepGuard: player → EQ (80 Hz high-pass, 1.5 kHz low-pass) → mixer; per-file boost to −3 dBFS; bypassed when enhanced audio is off.
- `.dataPlayedBack` completion plus a token, so paused or replaced spans never report finishing.
- Interruptions are reported once, while playing; the state owner stops (F5-T3).

### Build Status
- Package lanes pass (Adapters: 5 player + 10 storage); app builds; checks and format pass.
- Not heard yet: playback in the app comes with the player sheet (F5-T5).

### Next Session
- F5-T5: player sheet, Play on rows and cards, Debug sample clips.
