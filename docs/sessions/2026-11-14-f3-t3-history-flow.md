
### Completed
- F3-T3: composers, `HistoryFlow`, `TabFlow`, use-case registrations, `NoSleepStages`; the Sessions tab shows the real list, opens a night, and deletes it after confirmation, then pops.

### Technical Details
- Opening a night passes its `NightSummary`; the detail's title is the night's date, delete is a `BarItem`.
- Delete asks first: a `UIAlertController` presented through the navigator (`PresentationStyle.alert`, new in ScreenKit). The delete runs in a flow-owned task; success pops, failure stays (logged).
- Screens' `routes` / `dependencies` are internal (not private) so flow tests can trigger a route.
- Large title over a hosted SwiftUI `List`: UIKit never creates the large-title view (bar at large height, only the inline label exists). Ruled out: bar resizing, a `List` loading placeholder, bar appearances. The list uses an inline title.
- Visual checks: `drawHierarchy` screenshots were misleading (ring, cards); simulator screenshots (`simctl io screenshot`) are the reference.
- Shared: two new strings (`session.delete.confirmTitle`, `session.delete.confirmMessage`) released in shared 0.5.0; this branch is bumped to it (`bump-shared.sh 0.5.0`).

### Build Status
- Against shared 0.5.0 (release, as CI builds): Adapters 9, ScreenKit 12, Features 9, shell 19; in-app tests pass in SleepGuard, SleepGuardLite and Nocturne; checks and format pass.
- Nocturne list checked on the simulator (inline title).

### Next Session
- F3-T4: events sheet.
