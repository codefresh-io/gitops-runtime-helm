#!/bin/bash
set -eux

# convert the changelog into YAML list
export NOTES=$(
    echo "${CHART_CHANGELOG}" \
    | sed -e 's/.*/"&"/' \
    | jq --slurp \
    | jq '[.[] | {"type": "changed", "description": .}]' \
    | yq -p json -o yaml
)

CHART_YAML=${CHART_DIR}/Chart.yaml

yq -i '.annotations["artifacthub.io/changes"] |= strenv(NOTES)' ${CHART_YAML}

APP_VERSION=$(yq -r '.appVersion' ${CHART_YAML})
export APP_VERSION=$(semver-cli inc patch "${APP_VERSION}")

yq -i '.version    |= env(NEXT_VERSION)' ${CHART_YAML}
yq -i '.appVersion |= env(APP_VERSION)'  ${CHART_YAML}
