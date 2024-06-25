#!/bin/bash
set -eux

PREV_APP_PROXY_TAG=$(git show ${PREVIOUS_VERSION}:charts/gitops-runtime/values.yaml | yq '.app-proxy.image.tag')
CURR_APP_PROXY_TAG=$(cat                          charts/gitops-runtime/values.yaml | yq '.app-proxy.image.tag')

CHANGELIST_HEADER=""

### Detect direction of changes

if semver-cli equal ${CURR_APP_PROXY_TAG} ${PREV_APP_PROXY_TAG}; then
    echo "No changes in this release"
    exit
fi
if semver-cli greater ${CURR_APP_PROXY_TAG} ${PREV_APP_PROXY_TAG}; then
    CHANGELIST_HEADER="Introduced changes:"
    START_TAG=${PREV_APP_PROXY_TAG}
    END_TAG=${CURR_APP_PROXY_TAG}
fi
if semver-cli lesser ${CURR_APP_PROXY_TAG} ${PREV_APP_PROXY_TAG}; then
    CHANGELIST_HEADER="Reverted changes:"
    START_TAG=${CURR_APP_PROXY_TAG}
    END_TAG=${PREV_APP_PROXY_TAG}
fi

### Get time range for PRs

cd "${APP_PROXY_REPO_DIR}"
START=$(git show ${START_TAG} --quiet --format="%aI")
# exclude the tip of the last release
START=$(date --iso-8601=seconds --date="${START} + 1 second")
END=$(git show ${END_TAG} --quiet --format="%aI")

### Get PR titles

LABEL="component/app-proxy"
CHANGELIST=$(gh pr list \
    --repo codefresh-io/argo-platform \
    --label "${LABEL}" \
    --search "merged:${START}..${END}" \
    --json title --jq '.[].title' \
    | sed -e 's/^/* /' # add Markdown bullet point
)

echo "
${CHANGELIST_HEADER}
${CHANGELIST}
"
