#!/usr/bin/env bash

# Usage: openshift/release/mirror-upstream-branches.sh
# This should be run from the basedir of the repo with no arguments

set -Eeuo pipefail
readonly TMPDIR=$(mktemp -d knativePkgBranchingCheckXXXX -p /tmp/)

git fetch upstream
git fetch openshift

# We need to seed this with a few releases that, otherwise, would make
# the processing regex less clear with more anomalies
cat >> "$TMPDIR"/midstream_branches <<EOF
0.2
0.3
EOF

git branch --list -a "upstream/release-0.*" | cut -f3 -d'/' | cut -f2 -d'-' > "$TMPDIR"/upstream_branches
git branch --list -a "openshift/release-v0.*" | cut -f3 -d'/' | cut -f2 -d'v' | rev | cut -f2- -d'.' | rev >> "$TMPDIR"/midstream_branches

sort -o "$TMPDIR"/midstream_branches "$TMPDIR"/midstream_branches
sort -o "$TMPDIR"/upstream_branches "$TMPDIR"/upstream_branches
comm -32 "$TMPDIR"/upstream_branches "$TMPDIR"/midstream_branches > "$TMPDIR"/new_branches

UPSTREAM_BRANCH=$(cat "$TMPDIR"/new_branches)
if [ -z "$UPSTREAM_BRANCH" ]; then
    echo "no new branch, exiting"
    exit 0
fi
echo "found upstream branch: $UPSTREAM_BRANCH"
readonly UPSTREAM_TAG="v$UPSTREAM_BRANCH.0"
readonly MIDSTREAM_BRANCH="release-v$UPSTREAM_BRANCH.0"
openshift/release/create-release-branch.sh "$UPSTREAM_TAG" "$MIDSTREAM_BRANCH"
# we would check the error code, but we 'set -e', so assume we're fine
git push openshift "$MIDSTREAM_BRANCH"
