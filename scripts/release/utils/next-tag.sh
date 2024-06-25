#!/bin/bash
set -eux

echo $PREVIOUS_VERSION | grep -q cutoff
if [ $? -eq 0 ]; then
    echo ${GIT_BRANCH##release/}.0 # first patch release
else
    semver-cli inc patch $PREVIOUS_VERSION # next patch release
fi
