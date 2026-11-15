
### Completed
- F4-T5: the Statistics tab is live (`StatisticsFlow`, `StatisticsComposer`). F4 is done; feature doc written.

### Technical Details
- `NightDetailNavigation` holds opening a night (detail, events sheet, delete confirmation, delete then pop), so the Sessions and Statistics tabs share it; `HistoryFlow` keeps its tests.
- Start recording is the app's flow, not a tab's: `StatisticsFlow` calls up to `AppCoordinator.startRecording()`, which logs until F7. New `Log.app` category.
- Large title works over the dashboard's `ScrollView`; only a hosted `List` lacked it (F3).

### Build Status
- Shell 26 (6 new); package lanes and in-app tests per brand: see handover. Shared 0.9.0 (no shared change in this task).
- Seen on the simulator: the dashboard in SleepGuard. The pushed calendar wasn't captured (the push is tested).

### Next Session
- F5: clip playback.
