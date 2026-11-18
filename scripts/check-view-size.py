#!/usr/bin/env python3
"""View size check (AGENTS.md "Screens").

Any Swift file in Packages/*/Sources/ that declares a SwiftUI view or a view
controller (`*ViewController.swift`, `*Controller.swift`) may have at most 200
lines; a SwiftUI screen container (`*Screen.swift`) at most 100. A file over
its limit fails unless it is in ALLOWLIST, and an allowlisted file fails if it
grows past its recorded ceiling or is back within the limit (delete the entry).
The allowlist can only shrink.

Exits 1 with a listing when any check fails.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
VIEW_LIMIT = 200
SCREEN_LIMIT = 100
DECLARES_VIEW = re.compile(r"^\s*(?:public\s+|internal\s+|private\s+|fileprivate\s+)?struct\s+\w+(?:<[^>]*>)?\s*:\s*[^{]*\bView\b", re.M)

# path -> (ceiling, reason). Empty, and meant to stay that way.
ALLOWLIST: dict[str, tuple[int, str]] = {}


def main() -> int:
    failures = []
    seen = set()
    checked = 0
    for path in sorted((ROOT / "Packages").glob("*/Sources/**/*.swift")):
        if "/.build/" in str(path):
            continue
        text = path.read_text(encoding="utf-8")
        if not DECLARES_VIEW.search(text) and not path.name.endswith("Controller.swift"):
            continue
        checked += 1
        rel = path.relative_to(ROOT).as_posix()
        lines = text.count("\n")
        limit = SCREEN_LIMIT if path.name.endswith("Screen.swift") else VIEW_LIMIT
        if rel in ALLOWLIST:
            seen.add(rel)
            ceiling, _ = ALLOWLIST[rel]
            if lines > ceiling:
                failures.append(f"{rel}: {lines} lines, grew past its allowlisted {ceiling}; split it instead")
            elif lines <= limit:
                failures.append(f"{rel}: {lines} lines, now within {limit}; delete its ALLOWLIST entry")
        elif lines > limit:
            failures.append(f"{rel}: {lines} lines (limit {limit}); split it")

    for rel in sorted(set(ALLOWLIST) - seen):
        failures.append(f"{rel}: allowlisted but not found; delete its ALLOWLIST entry")

    if failures:
        print("View size violations (see AGENTS.md 'Screens'):")
        for failure in failures:
            print(f"  {failure}")
        return 1
    print(f"View size check passed ({checked} view files).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
