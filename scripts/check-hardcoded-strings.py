#!/usr/bin/env python3
"""Hardcoded-string check (AGENTS.md "Localization").

User-facing text goes through `Strings.x` (SleepStrings, in the shared repo).
Scans every Swift source file in Packages/*/Sources and Apps/*/Sources (not
tests) and fails on:

  1. A literal with letters passed to Text, Button, Label, navigationTitle,
     ScreenChrome(title:), BarItem(accessibilityLabel:), accessibilityLabel,
     accessibilityValue or accessibilityHint.
  2. `String(localized:)`, which bypasses the generated accessor.

Allowed: lines inside `#if DEBUG`, interpolation-only literals, and literals of
two characters or fewer or with no letters (decorative punctuation, symbols).
Exits 1 with a file:line listing.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

LITERAL = r'"((?:[^"\\]|\\.)*)"'
CALLS = [
    re.compile(r"\b(Text|Button|Label)\(\s*" + LITERAL),
    re.compile(r"\.(navigationTitle|accessibilityLabel|accessibilityValue|accessibilityHint)\(\s*" + LITERAL),
    re.compile(r"\b(ScreenChrome)\([^)]*?\btitle:\s*" + LITERAL),
    re.compile(r"\b(BarItem)\([^)]*?\baccessibilityLabel:\s*" + LITERAL),
]
BYPASS = re.compile(r"\bString\(localized:")
HAS_LETTER = re.compile(r"[A-Za-z]")


def debug_lines(lines: list[str]) -> set[int]:
    """1-based line numbers inside `#if DEBUG` regions."""
    inside: set[int] = set()
    stack: list[bool] = []
    for number, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("#if"):
            stack.append(stripped[3:].strip() == "DEBUG")
        elif stripped.startswith("#elseif") and stack:
            stack[-1] = stripped[7:].strip() == "DEBUG"
        elif stripped.startswith("#else") and stack:
            stack[-1] = not stack[-1]
        elif stripped.startswith("#endif") and stack:
            stack.pop()
        if any(stack):
            inside.add(number)
    return inside


def exempt(literal: str) -> bool:
    return "\\(" in literal or len(literal) <= 2 or not HAS_LETTER.search(literal)


def main() -> int:
    files = sorted(
        path
        for pattern in ("Packages/*/Sources/**/*.swift", "Apps/*/Sources/**/*.swift")
        for path in ROOT.glob(pattern)
        if "/.build/" not in str(path)
    )
    violations = []
    for path in files:
        rel = path.relative_to(ROOT).as_posix()
        lines = path.read_text(encoding="utf-8").splitlines()
        skipped = debug_lines(lines)
        for number, line in enumerate(lines, 1):
            if number in skipped or line.lstrip().startswith("//"):
                continue
            for pattern in CALLS:
                for match in pattern.finditer(line):
                    if not exempt(match.group(2)):
                        violations.append(f'{rel}:{number}: hardcoded string in {match.group(1)}: "{match.group(2)}"')
            if BYPASS.search(line):
                violations.append(f"{rel}:{number}: String(localized:) bypasses Strings")

    if violations:
        print("Hardcoded strings (see AGENTS.md 'Localization'); add them to the shared catalog and use Strings.x:")
        for violation in violations:
            print(f"  {violation}")
        return 1
    print(f"Hardcoded-string check passed ({len(files)} files).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
