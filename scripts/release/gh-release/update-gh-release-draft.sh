#!/bin/bash
set -eux

APP_PROXY_CHANGELOG=$(${RELEASE_SCRIPTS}/utils/app-proxy-changelog.sh)

NOTES_FILE=$(mktemp)
echo "# Chart changes"  > ${NOTES_FILE}
echo "${CHART_CHANGELOG}" \
    | sed -e 's/^/* /' >> ${NOTES_FILE}
echo "# App-proxy changes"  >> ${NOTES_FILE}
echo "${APP_PROXY_CHANGELOG}" >> ${NOTES_FILE}

RELEASE_ARGUMENTS="${NEXT_VERSION} \
    --title ${NEXT_VERSION} \
    --target ${GIT_BRANCH} \
    --draft \
    --notes-file ${NOTES_FILE}"

gh release view ${NEXT_VERSION} > /dev/null

if [ $? -ne 0 ]; then
    gh release create ${RELEASE_ARGUMENTS}
else
    gh release edit ${RELEASE_ARGUMENTS}
fi
