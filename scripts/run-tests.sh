#!/bin/sh
# Runs every test lane and builds every package on its own.
#
#   1. macOS:     `swift test` in Packages/Core (the domain; seconds).
#   2. Packages:  each package built standalone on the simulator, each in its
#                 own derived data. Xcode lets a module import anything already
#                 built in the same derived data (the app workspace, or another
#                 package's build), so isolation catches an import of a module
#                 no target in the package declares. One a sibling target
#                 declares still leaks; check-layering.py catches that.
#                 Packages with tests run them here.
#   3. In-app:    `tuist generate`, then each brand's `<Brand>HostedTests`
#                 inside that brand's app (presentation, brand bootstrap).
#
# Every xcodebuild test run has a per-test time limit, so a hang fails fast.
#
# Usage: sh scripts/run-tests.sh [lane ...]    lanes: macos packages hosted (default: all)
# Env:   DESTINATION  (default: the pinned iPhone 16e, iOS 26.2 simulator)
#        TUIST_SHARED_RELEASE=1 to build the pinned shared release instead of ../SleepGuardShared
set -u
cd "$(dirname "$0")/.."
ROOT=$(pwd)

DESTINATION=${DESTINATION:-"platform=iOS Simulator,id=BD630AD5-5A05-4663-8F1B-A17283EBCBF5"}
DERIVED_DATA="$ROOT/.build/test-derived-data"
LOG_DIR="$DERIVED_DATA/logs"
TIMEOUTS="-test-timeouts-enabled YES -default-test-execution-time-allowance 30 -maximum-test-execution-time-allowance 60"
LANES=${*:-macos packages hosted}
# Every brand: each has Apps/<Brand>/Sources/Brand.swift (and an entry in Brand.all).
BRANDS=$(for f in Apps/*/Sources/Brand.swift; do basename "$(dirname "$(dirname "$f")")"; done)
mkdir -p "$LOG_DIR"
FAILED=""

# run <label> <log> <command…>: prints one result line, keeps the log.
run() {
  label=$1 log=$2
  shift 2
  printf '▶ %s … ' "$label"
  if "$@" >"$log" 2>&1; then
    grep -m1 -E 'Test run with .* passed|\*\* BUILD SUCCEEDED' "$log" || echo "ok"
  else
    echo "FAILED (log: $log)"
    grep -E 'error:|✘' "$log" | sort -u | head -15
    FAILED="$FAILED $label"
  fi
}

for lane in $LANES; do
  case $lane in
  macos)
    run "Core (macOS)" "$LOG_DIR/core-macos.log" sh -c "cd Packages/Core && swift test"
    ;;
  packages)
    for package in Core Adapters Presentation Features AppShell; do
      scheme=$(cd "Packages/$package" && xcodebuild -list 2>/dev/null | sed -n '/Schemes:/,$p' | grep -E "^ +$package(-Package)?$" | tail -1 | tr -d ' ')
      action=build
      grep -q 'testTarget' "Packages/$package/Package.swift" && [ "$package" != Core ] && action=test
      # Own derived data per package: a module another package built would
      # otherwise be importable here, which is exactly what this lane checks.
      run "$package ($action, standalone)" "$LOG_DIR/$package.log" sh -c \
        "cd Packages/$package && xcodebuild $action -scheme $scheme -destination '$DESTINATION' -derivedDataPath '$DERIVED_DATA/packages/$package' $TIMEOUTS"
    done
    ;;
  hosted)
    run "tuist generate" "$LOG_DIR/generate.log" tuist generate --no-open
    for brand in $BRANDS; do
      # shellcheck disable=SC2086
      run "${brand}HostedTests" "$LOG_DIR/$brand-hosted.log" xcodebuild test -workspace SleepGuardUIKitWay.xcworkspace \
        -scheme "${brand}HostedTests" -destination "$DESTINATION" -derivedDataPath "$DERIVED_DATA" $TIMEOUTS
    done
    ;;
  *)
    echo "unknown lane: $lane (macos, packages, hosted)"
    exit 2
    ;;
  esac
done

if [ -n "$FAILED" ]; then
  echo "Failed:$FAILED"
  exit 1
fi
echo "All lanes passed."
