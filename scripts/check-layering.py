#!/usr/bin/env python3
"""Layering check: module boundaries and project-wide bans (AGENTS.md).

Package manifests stop an undeclared import only when a package builds on its
own; inside the app workspace Xcode lets any already-built module be imported.
So this script checks imports against the module table in AGENTS.md, plus:

  1. Imports: each module in Packages/*/Sources/<Module>/ may import only the
     modules listed in ALLOWED_IMPORTS. A module missing from the table fails,
     so a new module has to be placed in it.
  2. Concurrency escape hatches (`@unchecked Sendable`, `nonisolated(unsafe)`,
     `@preconcurrency`) anywhere in Packages/ or Apps/, tests included.
  3. No `print(`: use os.Logger.
  4. No `.shared` singletons in packages (Factory's `Container.shared` in
     AppShell's bootstrap is the one exception).
  5. Feature modules (Packages/Features/) don't use SwiftUI navigation or
     persistence APIs, DI property wrappers, or UIKit globals: UIKit owns
     navigation, adapters own persistence, composers own DI.

Lines starting with `//` are ignored. Exits 1 with a file:line listing.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Always allowed: the standard library and Apple's base frameworks.
BASE = {"Foundation", "Swift", "os", "OSLog", "Observation"}

# Module -> imports it may use besides BASE. Mirrors the table in AGENTS.md.
ALLOWED_IMPORTS = {
    "SleepDomain": {"SleepCore"},
    "SleepDomainTestSupport": {"SleepDomain", "SleepCore"},
    "SleepPersistence": {"SleepDomain", "SleepCore", "SwiftData"},
    "SleepAudio": {"SleepDomain", "SleepCore", "AVFoundation", "AVFAudio", "SoundAnalysis", "Accelerate"},
    "SleepHealth": {"SleepDomain", "SleepCore", "HealthKit"},
    "ScreenKit": {"UIKit", "SwiftUI", "SleepGuardDesignKit"},
    "AppShell": {
        "UIKit", "SwiftUI", "FactoryKit", "SleepDomain", "SleepCore", "SleepPersistence", "SleepAudio",
        "ScreenKit", "SleepGuardDesignKit", "SleepStrings", "HistoryFeature", "SessionDetailFeature",
    },
    "AppShellTestSupport": {"AppShell", "UIKit", "SwiftUI", "ScreenKit", "SleepGuardDesignKit"},
}

# Every module under Packages/Features/ (they don't exist yet; F3 adds the first).
FEATURE_IMPORTS = {"SwiftUI", "Charts", "SleepDomain", "SleepCore", "SleepGuardDesignKit", "SleepStrings"}

ESCAPE_HATCH = re.compile(r"@unchecked\s+Sendable|nonisolated\(unsafe\)|@preconcurrency")
# Paths allowed an escape hatch, with the reason. Keep it empty if you can.
ESCAPE_HATCH_ALLOWLIST: dict[str, str] = {}

PRINT_CALL = re.compile(r"(?<![\w.])print\(")
SHARED = re.compile(r"\b([A-Z]\w*)\.shared\b")
SHARED_ALLOWLIST = {("Packages/AppShell/Sources/AppShell/AppShell.swift", "Container")}

FEATURE_BANNED = re.compile(
    r"\b(NavigationStack|NavigationLink|NavigationSplitView)\b"
    r"|\.(navigationDestination|sheet|fullScreenCover|popover|navigationTitle|toolbar)\b"
    r"|@(Query|Injected|LazyInjected)\b"
    r"|\bmodelContext\b"
    r"|\b(UIApplication|UIDevice)\b"
)

IMPORT = re.compile(r"^\s*(?:@testable\s+|@_exported\s+)?import\s+(?:(?:struct|class|enum|protocol|func|var|let)\s+)?([\w]+)")


def module_of(rel: str) -> str | None:
    parts = rel.split("/")
    # Packages/<Package>/Sources/<Module>/...
    if len(parts) > 4 and parts[0] == "Packages" and parts[2] == "Sources":
        return parts[3]
    return None


def code_lines(path: pathlib.Path):
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.lstrip().startswith("//"):
            yield number, line


def main() -> int:
    violations = []
    swift_files = sorted(
        path for base in ("Packages", "Apps") for path in (ROOT / base).rglob("*.swift") if "/.build/" not in str(path)
    )
    for path in swift_files:
        rel = path.relative_to(ROOT).as_posix()
        module = module_of(rel)
        is_feature = rel.startswith("Packages/Features/") and module is not None
        allowed = FEATURE_IMPORTS if is_feature else ALLOWED_IMPORTS.get(module) if module else None
        if module and allowed is None:
            violations.append(f"{rel}: module '{module}' is not in ALLOWED_IMPORTS; add it (and to AGENTS.md)")

        for number, line in code_lines(path):
            if module and allowed is not None:
                match = IMPORT.match(line)
                if match and match.group(1) not in BASE | allowed:
                    violations.append(f"{rel}:{number}: '{module}' may not import {match.group(1)}")
            if ESCAPE_HATCH.search(line) and rel not in ESCAPE_HATCH_ALLOWLIST:
                violations.append(f"{rel}:{number}: concurrency escape hatch: {line.strip()}")
            if PRINT_CALL.search(line):
                violations.append(f"{rel}:{number}: print( — log through os.Logger")
            if module:
                for match in SHARED.finditer(line):
                    if (rel, match.group(1)) not in SHARED_ALLOWLIST:
                        violations.append(f"{rel}:{number}: {match.group(0)} — inject it instead")
            if is_feature:
                match = FEATURE_BANNED.search(line)
                if match:
                    violations.append(f"{rel}:{number}: '{match.group(0)}' is not allowed in a feature module")

    if violations:
        print("Layering violations (see AGENTS.md):")
        for violation in violations:
            print(f"  {violation}")
        return 1
    print(f"Layering check passed ({len(swift_files)} files scanned).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
