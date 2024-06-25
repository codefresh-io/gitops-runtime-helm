#!/bin/bash
set -eux

### look for latest on-branch tag
TAG=$(git describe --tags --abbrev=0 --match "${GIT_BRANCH##release/}*" 2>/dev/null || true)

if [ -n "$TAG" ]; then
    echo $TAG
    exit 0
fi

### fall back to previous cutoff tag
# get previous cutoff point
CUTOFF_COMMIT=$(git merge-base main HEAD)
PREV_CUTOFF_TAG=$(git describe --tags --abbrev=0 --match "cutoff-*" ${CUTOFF_COMMIT}~1 2>/dev/null)
echo $PREV_CUTOFF_TAG
