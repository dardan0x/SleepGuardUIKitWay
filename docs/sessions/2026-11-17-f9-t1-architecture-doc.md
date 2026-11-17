
### Completed
- F9-T1: `docs/ARCHITECTURE.md`, the whole system as built, checked against the code.

### Technical Details
- **Module graph**: `tuist graph` stops at what the apps link directly, so it shows only the brands → AppShell, the design kit, and SleepHealth for brands with Health. The package graph comes from the manifests (`swift package dump-package`, non-test targets) and is drawn in Mermaid.
- **Sections**:
  - each layer with its size and limits;
  - a night's detail end to end (intent → flow → composer → hosted screen → use case → shared content);
  - brands and their capability values;
  - the shared repo's products and how it's pinned;
  - the recording pipeline;
  - every rule and what enforces it;
  - the three test lanes;
  - the ADRs;
  - where to look first.
- **Checked against the source**: file and line counts per module, 12 ports, 9 use cases, 21 screens, 9 flows and coordinators, 28 container registrations, about 210 package tests plus 9 in-app per brand, the layering script's rules, and Nocturne's theme and tab order.
- **Corrected along the way**: `docs/architecture/overview.md` said `SleepDomain` depends on nothing; it depends on the shared `SleepCore`.

### Files Changed
| File | What Changed |
|------|--------------|
| `docs/ARCHITECTURE.md` | New |
| `docs/architecture/{overview,INDEX}.md` (git-ignored, local only) | One correction; points to the new doc |
| `docs/trackers/f9-showcase-polish.md`, `docs/FeatureTracker.md`, `docs/Roadmap.md` | F9-T1 |

### Build Status
- Docs only; no code changed.

### Next Session
- F9-T2: a fourth brand as a worked example, with its diff.

### Open Questions
- None.
