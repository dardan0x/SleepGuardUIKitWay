# Session Log

Each coding session is its own file. Branches only ever add files here, so session logs never merge-conflict and session numbers never go stale.

## How it works

- **Fragments** (`YYYY-MM-DD-slug.md`) are the source of truth. One sitting = one fragment, even if it touched more than one feature (set `feature:` to the primary one, or `multiple`).
- **`docs/SESSION_SUMMARY.md`** is generated and git-ignored: every fragment concatenated, with session numbers injected. Never hand-edit it.
- **Fragments carry no session number.** `python3 scripts/compile-sessions.py` sorts them by date and numbers them from 1. Run it only when you want to read the combined log.

## Fragment template

```markdown
---
date: 2026-11-14
feature: F1              # feature ID, "none" for a standalone fix, or "multiple"
branch: feature/f1/t2-tuist-project
title: Short description of the session
---

### Completed
- [Task ID]: [What was built, in technical detail]

### Technical Details
- [Specific implementation detail]

### Files Changed
| File | What Changed |
|------|--------------|
| `path/to/file.swift` | [Description] |

### Architecture Decisions
- **[Decision name]**: [Why this approach over alternatives; link the ADR if one was written]

### Build Status
- **BUILD SUCCEEDED / FAILED** per brand scheme, tests run and their counts, checks run. Say what was not verified.

### Suggested Branch
`feature/[f#]/[t#]-short-description`

### Suggested Commit
`[Task ID] — [Short description]`

### Next Session
- [Task ID]: [What to start next and why]

### Open Questions
- [Question that needs a decision]
```
