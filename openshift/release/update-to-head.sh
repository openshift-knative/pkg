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

echo "::debug:: Check if there's an upstream release we need to mirror downstream"
openshift/release/mirror-upstream-branches.sh

echo "::debug:: Reset release-next to upstream/$MAIN_BRANCH."
git fetch "${UPSTREAM}" "$MAIN_BRANCH"
git checkout "${UPSTREAM}/${MAIN_BRANCH}" -B release-next

echo "::debug:: Remove upstream Github workflow files"
rm -rfv .github/workflows

echo "::debug:: Update openshift's $MAIN_BRANCH and take all needed files from there."
git fetch "${OPENSHIFT}" "$MAIN_BRANCH"
git checkout "${OPENSHIFT}/$MAIN_BRANCH" -- .
git add .
git commit -m ":open_file_folder: Update OpenShift specific files."

echo "::debug:: Apply patches if present"
PATCHES_DIR="$(pwd)/openshift/patches/"
if [ -d "$PATCHES_DIR" ] && [ "$(ls -A "$PATCHES_DIR")" ]; then
  git apply openshift/patches/*
  git commit -am ":fire: Apply carried patches."
fi
git push -f "${OPENSHIFT}" release-next

echo "::debug:: Trigger CI"
git checkout release-next -B release-next-ci
date > ci
git add ci
git commit -m ":robot: Triggering CI on branch 'release-next' after synching to ${UPSTREAM}/${MAIN_BRANCH}"
git push -f "${OPENSHIFT}" release-next-ci

echo "::debug:: Create a sync PR"
if command -v gh 2>/dev/null 1>&2; then
  gh pr create \
    --title "$(git show -s --format=%s --no-show-signature)" \
    --body '' \
    --repo "${ORGANISATION}/${REPO_NAME}" \
    --base 'release-next' --head 'release-next-ci'
else
   echo "::warning:: gh (https://github.com/cli/cli) is not installed, so \
you'll need to create a PR manually." >&2
fi
