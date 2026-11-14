#!/bin/sh
# Moves the app to a released version of SleepGuardShared.
#
# Release first, in ../SleepGuardShared: merge, then
#   git tag -a 0.3.0 -m "…" && git push origin 0.3.0
#
# Usage: sh scripts/bump-shared.sh 0.3.0
#
# Rewrites the version everywhere it is pinned (`exact:` in every package
# manifest that depends on SleepGuardShared, and `sharedVersion` in
# Project.swift), then re-resolves each of those packages so its committed
# Package.resolved follows.
set -eu
cd "$(dirname "$0")/.."

VERSION=${1:?usage: sh scripts/bump-shared.sh <version>}
URL=https://github.com/dardan0x/SleepGuardShared.git

if ! git ls-remote --exit-code --tags "$URL" "refs/tags/$VERSION" >/dev/null; then
  echo "error: tag $VERSION not found on $URL; push the tag first" >&2
  exit 1
fi

MANIFESTS=$(grep -l "SleepGuardShared.git" Packages/*/Package.swift)
for manifest in $MANIFESTS; do
  sed -i '' -E "s#(SleepGuardShared\.git\", exact: \")[^\"]+#\1$VERSION#" "$manifest"
done
sed -i '' -E "s#^(let sharedVersion: Version = \")[^\"]+#\1$VERSION#" Project.swift

for manifest in $MANIFESTS; do
  (cd "$(dirname "$manifest")" && swift package resolve >/dev/null)
done

echo "SleepGuardShared $VERSION in:"
grep -H "SleepGuardShared.git" $MANIFESTS | sed 's/:.*exact: / /; s/),$//'
grep -H "let sharedVersion" Project.swift
echo "Next: sh scripts/run-tests.sh, then commit the manifests, Package.resolved files and Project.swift."
