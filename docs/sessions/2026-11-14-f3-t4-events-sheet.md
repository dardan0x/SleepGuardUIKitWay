
### Completed
- F3-T4: events sheet. "Show all" on a night's detail opens a UIKit sheet (medium/large) with every event under the current filter as cards; close returns to the detail.

### Technical Details
- The route carries the rows on screen (`showAllEvents: ([DetailEventRow]) -> Void`), so the sheet matches the filter without reloading.
- `DetailEventRow` is public with an internal init: other modules pass rows on, only the feature makes them.
- The sheet is a `HostingScreen` in its own `UINavigationController` (bar title and close button through `ScreenChrome`, bar themed by `Appearance`).
- `DetailEventRow.color(in:)` is the one colour rule for list rows and cards.
- Card start-time line shrinks to fit (three cards in 390 pt).

### Build Status
- Package lanes and in-app tests in all three brands: see handover. Checks and format pass.
- Seen: card renders in two themes; in-app capture of the sheet at medium detent (Nocturne). The simulator-screenshot loop missed the sheet's moment.

### Next Session
- F3-T5: timeline, stats grid, legends, event row, score badge and night row into the shared design kit.
