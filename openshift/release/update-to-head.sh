#!/usr/bin/env bash

# Synchs the release-next branch to $MAIN_BRANCH and then triggers CI
# Usage: update-to-head.sh

set -Eeuo pipefail

export ORGANISATION="${ORGANISATION:-openshift-knative}"
export UPSTREAM="${UPSTREAM:-upstream}"
export OPENSHIFT="${OPENSHIFT:-openshift}"
export MAIN_BRANCH="${MAIN_BRANCH:-main}"
REPO_NAME="${REPO_NAME:-$(basename "$(git rev-parse --show-toplevel)" \
 | sed 's/knative[-_]//g')}"

# Check if there's an upstream release we need to mirror downstream
openshift/release/mirror-upstream-branches.sh

# Reset sync-candidate to upstream/$MAIN_BRANCH.
git fetch "${UPSTREAM}" "$MAIN_BRANCH"
git checkout "${UPSTREAM}/${MAIN_BRANCH}" -B sync-candidate

# Remove upstream Github files
rm -rfv .github

# Update openshift's $MAIN_BRANCH and take all needed files from there.
git fetch "${OPENSHIFT}" "$MAIN_BRANCH"
git checkout "${OPENSHIFT}/$MAIN_BRANCH" -- .
git add .
git commit -m ":open_file_folder: Update OpenShift specific files."

# Apply patches if present
PATCHES_DIR="$(pwd)/openshift/patches/"
if [ -d "$PATCHES_DIR" ] && [ "$(ls -A "$PATCHES_DIR")" ]; then
  git apply openshift/patches/*
  git commit -am ":fire: Apply carried patches."
fi
git push -f "${OPENSHIFT}" sync-candidate

# Create a sync PR
if command -v hub 2>/dev/null 1>&2; then
   hub pull-request --no-edit \
     --labels "kind/sync-fork-to-upstream" \
     --base "${ORGANISATION}/${REPO_NAME}:release-next" \
     --head "${ORGANISATION}/${REPO_NAME}:sync-candidate"
else
   echo "hub (https://github.com/github/hub) is not installed, so you'll need to create a PR manually."
fi
