#!/usr/bin/env bash

# Usage: openshift/release/mirror-upstream-branches.sh
# This should be run from the basedir of the repo with no arguments

set -Eeuo pipefail

export UPSTREAM="${UPSTREAM:-upstream}"
export OPENSHIFT="${OPENSHIFT:-openshift}"
readonly TMPDIR=$(mktemp -d openshift-knatove-pkg-mirror-branches-XXXXX -p /tmp/)
cleanup() {
  rm -rf "${TMPDIR}"
}
trap cleanup EXIT

git remote prune "${UPSTREAM}"
git fetch "${UPSTREAM}"
git remote prune "${OPENSHIFT}"
git fetch "${OPENSHIFT}"

git branch --list -a "${UPSTREAM}/release-*" \
  | cut -f3 -d'/' \
  | cut -f2 -d'-' > "$TMPDIR"/upstream_branches
git branch --list -a "${OPENSHIFT}/release-*" \
  | cut -f3 -d'/' \
  | cut -f2 -d'-' > "$TMPDIR"/midstream_branches

sort -V -o "$TMPDIR"/midstream_branches "$TMPDIR"/midstream_branches
sort -V -o "$TMPDIR"/upstream_branches "$TMPDIR"/upstream_branches
comm -32 "$TMPDIR"/upstream_branches "$TMPDIR"/midstream_branches > "$TMPDIR"/new_branches

if ! [ -s "$TMPDIR"/new_branches ]; then
    echo "::debug:: no new branch, exiting"
    exit 0
fi

while read -r UPSTREAM_BRANCH; do
  echo "::debug:: found upstream branch: $UPSTREAM_BRANCH"
  MIDSTREAM_BRANCH="release-$UPSTREAM_BRANCH"
  openshift/release/create-release-branch.sh "$MIDSTREAM_BRANCH"
  git push "${OPENSHIFT}" "$MIDSTREAM_BRANCH" -f
done < "$TMPDIR"/new_branches
