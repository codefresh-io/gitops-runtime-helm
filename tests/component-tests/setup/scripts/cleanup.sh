#!/bin/bash
# -----------------------------------------------------------------------------
# cleanup.sh - Cleans up test repositories and restores test fixture files
#
# This script is used in the Codefresh GitOps Operator component test suite to:
#   - Remove cloned test repositories.
#   - Restore the runtime values and mock expectation JSON files to their original state.
#
# Usage:
#   ./cleanup.sh
#
# Steps performed:
#   - Deletes the codefresh-isc and simple-app directories.
#   - Restores runtime.values.yaml and mock JSON files to their initial state using git.
# -----------------------------------------------------------------------------
rm -rf ./test/component-tests/setup/codefresh-isc
rm -rf ./test/component-tests/setup/simple-app
git restore ./test/component-tests/setup/values/runtime.values.yaml
git restore ./test/component-tests/promotion/01-git-commit/00-app-sync.json
git restore ./test/component-tests/promotion/01-git-commit/01-app-promote.json