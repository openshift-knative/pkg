#!/bin/bash

# Usage: create-release-branch.sh release-0.4

# Exit immediately on any error.
set -Eeuo pipefail

release="${1:?Pass a upstream ref as arg[0]}"

export UPSTREAM="${UPSTREAM:-upstream}"
export OPENSHIFT="${OPENSHIFT:-openshift}"
export MAIN_BRANCH="${MAIN_BRANCH:-main}"

echo "::debug:: Fetch checkout a new branch."
git fetch "$UPSTREAM"
git checkout "${UPSTREAM}/${release}" -B "${release}"

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
