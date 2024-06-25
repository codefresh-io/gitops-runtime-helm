#!/bin/bash
set -eux

export GIT_ROOT=$(git rev-parse --show-toplevel)
export GIT_BRANCH=$(git branch --show-current)
export CHART_DIR=${GIT_ROOT}/charts/gitops-runtime
export RELEASE_SCRIPTS=${GIT_ROOT}/scripts/release

export PREVIOUS_VERSION=$(${RELEASE_SCRIPTS}/utils/previous-tag.sh)
export NEXT_VERSION=$(${RELEASE_SCRIPTS}/utils/next-tag.sh)
export CHART_CHANGELOG=$(git log --pretty=format:%s "${PREVIOUS_VERSION}..HEAD")

${RELEASE_SCRIPTS}/chart/update-chart-yaml.sh
${RELEASE_SCRIPTS}/chart/update-doc-links.sh
${RELEASE_SCRIPTS}/chart/update-helm-docs.sh
${RELEASE_SCRIPTS}/gh-release/update-gh-release-draft.sh
