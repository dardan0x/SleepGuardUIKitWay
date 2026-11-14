#!/usr/bin/env python3
"""Compile per-session fragment files into a single SESSION_SUMMARY.md.

Source of truth = the fragment files in docs/sessions/. This script is a
READ-TIME convenience: it concatenates them into a generated
docs/SESSION_SUMMARY.md (git-ignored). Never hand-edit the generated file.

Session numbers are DERIVED here, not authored in fragments: fragments are
sorted by date (then filename) and numbered from 1.

Fragment format (docs/sessions/YYYY-MM-DD-slug.md):

    ---
    date: 2026-11-14
    feature: F1             # or "none" for a standalone fix
    branch: feature/...
    title: Short description
    ---

    ### Completed
    - ...

Run:  python3 scripts/compile-sessions.py
"""

import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SESSIONS_DIR = REPO / "docs" / "sessions"
OUTPUT = REPO / "docs" / "SESSION_SUMMARY.md"

FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n?(.*)$", re.DOTALL)


def parse_frontmatter(text):
    """Return (meta_dict, body). Body is everything after the frontmatter."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}, text.strip()
    meta = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            key, _, val = line.partition(":")
            meta[key.strip()] = val.strip()
    return meta, m.group(2).strip()


def fragment_files():
    return sorted(p for p in SESSIONS_DIR.glob("*.md") if p.name != "README.md")


def sort_key(path):
    meta, _ = parse_frontmatter(path.read_text(encoding="utf-8"))
    # Prefer frontmatter date; fall back to the YYYY-MM-DD filename prefix.
    date = meta.get("date") or path.name[:10]
    return (date, path.name)


def main():
    parts = ["# SleepGuardUIKitWay — Session Summary"]
    number = 0
    for path in sorted(fragment_files(), key=sort_key):
        number += 1
        meta, body = parse_frontmatter(path.read_text(encoding="utf-8"))
        date = meta.get("date") or path.name[:10]
        title = meta.get("title") or path.stem[11:].replace("-", " ").title()
        parts.append(f"\n\n---\n\n## {date} — Session {number}: {title}\n\n{body}")

    OUTPUT.write_text("\n".join(parts).rstrip() + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT.relative_to(REPO)} ({number} fragment(s))")


if __name__ == "__main__":
    main()
