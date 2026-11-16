
### Completed
- F5-T5: the player sheet, Play on rows and cards, and Debug sample clips. F5 is done (feature doc written).
- Player components in the shared kit for 0.11.0.

### Technical Details
- The composer builds the state owner over a new player (`makeClipPlayer`, a main-actor maker because Factory's closures aren't main-actor); the screen starts it on appear and closes it on disappear.
- Play routes carry the clips to play, computed in the feature with SleepCore's episode rule; "Show all" now passes the night's events so the sheet can do the same.
- Sample clips: written off the main actor before the nights are saved; at most 15 s each.
- Fixed a racy in-app test (`debugLaunchHasSampleNights`) that fresh installs exposed.

### Build Status
- Against the local shared checkout: all package lanes pass (shell 28); in-app tests per brand: see handover. Shared: SleepCore 109, kit 9, strings 2.
- Seen on the simulator: the player playing over a night's detail. Bumped to shared 0.11.0: package lanes, SleepGuard and Nocturne in-app tests pass; Lite timed out once waiting for the store's nights, then passed on rerun (cause unknown, noted in the tracker).

### Next Session
- Decide F6 (design kit adoption in SleepGuard) or F7 (recording).
