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
  4. No `.shared` singletons in packages, `Container.shared` included: the
     app's container is `AppComposition`'s own (ADR 0009).
  5. Feature modules (Packages/Features/) don't use SwiftUI navigation or
     persistence APIs, DI property wrappers, UIKit globals, or UIKit
     navigation: coordinators own navigation (a screen presents only a
     `UIAlertController`, named `…alert` or `…Alert()`), adapters own
     persistence, factories own DI (ADR 0007).
  6. View models (`*ViewModel.swift` in a feature) import only Foundation,
     Observation, `SleepDomain` and `SleepCore`: no UIKit, SwiftUI or
     ScreenKit, so their logic is testable without a UI (ADR 0008).
  7. Every screen has a view model: a feature class that subclasses
     `ScreenController` declares `let viewModel` (ADR 0008).
  8. Declared imports: every target (tests included) imports a package module
     only if its Package.swift declares it (nothing is re-exported, rule 10). The workspace build doesn't check this, and a
     standalone build only does when no sibling target built the module
     first. Manifests are read with `swift package dump-package`.
  9. Themed hosting: only ScreenKit creates `UIHostingController` or
     `UIHostingConfiguration`. Everyone else hosts through its helpers
     (`host`, `render`, `hosted`, `Theme.hosting`), which put the brand's
     theme in the environment; the environment's default is SleepGuard's, so
     a hand-made host would draw another brand in SleepGuard's colours.
 10. No `@_exported import`: it hides where a type comes from and what a
     target depends on. A file imports every module it uses (shared 0.37.0
     removed the kits' re-exports too).

A screen presenting anything but an alert is a compile error
(`ScreenController.present` is unavailable), so rule 5's `present(` pattern
only backs it up for the few feature controllers that aren't screens.

Lines starting with `//` are ignored. Exits 1 with a file:line listing.
"""

import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Always allowed: the standard library and Apple's base frameworks.
BASE = {"Foundation", "Swift", "os", "OSLog", "Observation"}

# Module -> imports it may use besides BASE. Mirrors the table in AGENTS.md.
ALLOWED_IMPORTS = {
    "SleepDomain": {"SleepCore"},
    "SleepDomainTestSupport": {"SleepDomain", "SleepCore"},
    "SleepPersistenceAdapter": {"SleepDomain", "SleepCore", "SleepFiles", "SleepSettings", "SleepLogging", "SleepStore", "SwiftData"},
    "SleepAudioAdapter": {"SleepDomain", "SleepCore", "SleepAudioKit"},
    "SleepHealthAdapter": {"SleepDomain", "SleepCore", "SleepHealthKit", "SleepLogging"},
    "ScreenKit": {"UIKit", "SwiftUI", "SleepGuardDesignKit"},
    "AppShell": {
        "UIKit", "SwiftUI", "FactoryKit", "SleepDomain", "SleepCore", "SleepPersistenceAdapter", "SleepAudioAdapter",
        "ScreenKit", "SleepGuardDesignKit", "SleepStrings", "HistoryFeature", "SessionDetailFeature", "StatisticsFeature", "RecordingFeature",
        "SettingsFeature", "OnboardingFeature", "LearnFeature", "BriefingFeature",
        "SleepFiles", "SleepLogging", "SleepNotifications",
        # DeviceServices: the microphone permission and the start delay's notification.
        "AVFAudio", "UserNotifications",
    },
    "AppShellTestSupport": {"AppShell", "UIKit", "SwiftUI", "ScreenKit", "SleepGuardDesignKit", "SleepDomain"},
}

# Every module under Packages/Features/. Screens are UIKit controllers on
# ScreenKit that host the shared SwiftUI content (ADR 0007).
FEATURE_IMPORTS = {
    "UIKit", "SwiftUI", "ScreenKit", "SleepDomain", "SleepCore", "SleepGuardContentKit", "SleepGuardDesignKit",
    "SleepStrings",
}

# A feature's `*ViewModel.swift`: state and intents only, no UI framework.
VIEW_MODEL_IMPORTS = {"SleepDomain", "SleepCore"}

SCREEN_CLASS = re.compile(r"\bclass\s+(\w+)\s*:\s*ScreenController\b")
HAS_VIEW_MODEL = re.compile(r"\blet\s+viewModel\s*:")

ESCAPE_HATCH = re.compile(
    r"@unchecked\s+Sendable|nonisolated\(unsafe\)|@preconcurrency|uncheckedState|withLockUnchecked")
# Paths allowed an escape hatch, with the reason. Keep it as short as you can.
ESCAPE_HATCH_ALLOWLIST: dict[str, str] = {
}

PRINT_CALL = re.compile(r"(?<![\w.])print\(")
REEXPORT = re.compile(r"^\s*@_exported\s+import\b")
SHARED = re.compile(r"\b([A-Z]\w*)\.shared\b")
SHARED_ALLOWLIST = {
    # The device switches (screen on, Settings link, permissions), in one place.
    ("Packages/AppShell/Sources/AppShell/Recording/DeviceServices.swift", "UIApplication"),
    ("Packages/AppShell/Sources/AppShell/Recording/DeviceServices.swift", "AVAudioApplication"),
}

FEATURE_BANNED = re.compile(
    r"\b(NavigationStack|NavigationLink|NavigationSplitView)\b"
    r"|\.(navigationDestination|sheet|fullScreenCover|popover|navigationTitle|toolbar)\b"
    r"|@(Query|Injected|LazyInjected)\b"
    r"|\bmodelContext\b"
    r"|\b(UIApplication|UIDevice|UINavigationController|Navigator)\b"
    r"|\bnavigationController\b|\b(pushViewController|popViewController|showDetailViewController)\b"
    # Only alerts: `present(alert, …)`, `present(someAlert(), …)`, `present(confirmation(…), …)`.
    r"|\bpresent\((?!\w*[aA]lert\b|\w*Alert\(|\w*[cC]onfirmation\()"
)

HOSTING = re.compile(r"\bUIHosting(Controller|Configuration)\s*[({]")
HOSTING_OWNER = "Packages/Presentation/Sources/ScreenKit/"

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


# Re-exports (`@_exported import`) of products from outside this repo, which
# the script can't read. Re-exports inside Packages/ are read from the sources.
EXTERNAL_REEXPORTS = {
    "SleepGuardContentKit": {"SleepGuardDesignKit"},
    "SleepGuardDesignKit": {"SleepStrings"},
}

EXPORTED_IMPORT = re.compile(r"^\s*@_exported\s+import\s+(\w+)")


def undeclared_imports() -> list[str]:
    packages = sorted(path.parent for path in (ROOT / "Packages").glob("*/Package.swift"))
    manifests = {
        package: json.loads(subprocess.run(
            ["swift", "package", "dump-package", "--package-path", str(package)],
            check=True, capture_output=True, text=True).stdout)
        for package in packages
    }

    product_modules: dict[str, set[str]] = {}  # local product -> its targets
    target_dirs: dict[str, pathlib.Path] = {}
    target_package: dict[str, pathlib.Path] = {}
    for package, manifest in manifests.items():
        for product in manifest["products"]:
            product_modules[product["name"]] = set(product["targets"])
        for target in manifest["targets"]:
            default = "Tests" if target["type"] == "test" else "Sources"
            target_dirs[target["name"]] = package / (target.get("path") or f"{default}/{target['name']}")
            target_package[target["name"]] = package

    reexports = {module: set(names) for module, names in EXTERNAL_REEXPORTS.items()}
    for module, directory in target_dirs.items():
        for path in directory.rglob("*.swift"):
            for _, line in code_lines(path):
                match = EXPORTED_IMPORT.match(line)
                if match:
                    reexports.setdefault(module, set()).add(match.group(1))

    def modules_of(dependency: dict) -> set[str]:
        kind, value = next(iter(dependency.items()))
        name = value[0]
        if kind == "product":
            return product_modules.get(name, {name})
        return {name} if name in target_dirs else product_modules.get(name, {name})

    # Package modules: anything else imported (UIKit, SwiftData, ...) is the SDK's.
    known = set(target_dirs) | set(product_modules) | set(reexports) | set().union(*reexports.values())
    declared_by: dict[str, set[str]] = {}
    for manifest in manifests.values():
        for target in manifest["targets"]:
            modules = {target["name"]}
            for dependency in target["dependencies"]:
                modules |= modules_of(dependency)
            known |= modules
            pending = list(modules)
            while pending:
                for exported in reexports.get(pending.pop(), set()) - modules:
                    modules.add(exported)
                    pending.append(exported)
            declared_by[target["name"]] = modules

    violations = []
    for target, directory in sorted(target_dirs.items()):
        manifest = (target_package[target] / "Package.swift").relative_to(ROOT).as_posix()
        for path in sorted(directory.rglob("*.swift")):
            rel = path.relative_to(ROOT).as_posix()
            for number, line in code_lines(path):
                match = IMPORT.match(line)
                if match and match.group(1) in known - declared_by[target]:
                    violations.append(
                        f"{rel}:{number}: '{target}' imports {match.group(1)}, which {manifest} doesn't declare")
    return violations


def main() -> int:
    violations = undeclared_imports()
    swift_files = sorted(
        path for base in ("Packages", "Apps") for path in (ROOT / base).rglob("*.swift") if "/.build/" not in str(path)
    )
    for path in swift_files:
        rel = path.relative_to(ROOT).as_posix()
        module = module_of(rel)
        is_feature = rel.startswith("Packages/Features/") and module is not None
        allowed = FEATURE_IMPORTS if is_feature else ALLOWED_IMPORTS.get(module) if module else None
        if is_feature and path.name.endswith("ViewModel.swift"):
            allowed = VIEW_MODEL_IMPORTS
        if module and allowed is None:
            violations.append(f"{rel}: module '{module}' is not in ALLOWED_IMPORTS; add it (and to AGENTS.md)")

        if is_feature:
            text = path.read_text(encoding="utf-8")
            for screen in SCREEN_CLASS.findall(text):
                if not HAS_VIEW_MODEL.search(text):
                    violations.append(f"{rel}: screen '{screen}' has no `let viewModel` (ADR 0008)")

        for number, line in code_lines(path):
            if module and allowed is not None:
                match = IMPORT.match(line)
                if match and match.group(1) not in BASE | allowed:
                    violations.append(f"{rel}:{number}: '{module}' may not import {match.group(1)}")
            if ESCAPE_HATCH.search(line) and rel not in ESCAPE_HATCH_ALLOWLIST:
                violations.append(f"{rel}:{number}: concurrency escape hatch: {line.strip()}")
            if PRINT_CALL.search(line):
                violations.append(f"{rel}:{number}: print( — log through os.Logger")
            if REEXPORT.search(line):
                violations.append(f"{rel}:{number}: @_exported import — import the module where it is used and declare it")
            if module:
                for match in SHARED.finditer(line):
                    if (rel, match.group(1)) not in SHARED_ALLOWLIST:
                        violations.append(f"{rel}:{number}: {match.group(0)} — inject it instead")
            if module and not rel.startswith(HOSTING_OWNER) and HOSTING.search(line):
                violations.append(f"{rel}:{number}: host SwiftUI through ScreenKit (host, render, hosted, Theme.hosting)")
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
