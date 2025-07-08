#!/bin/bash
# -----------------------------------------------------------------------------
# 00-app-sync.sh - Updates app values and loads sync mock expectations
#
# This script is used in the Codefresh GitOps Operator component test suite to:
#   - Update the 'values.yaml' file in the simple-app repository.
#   - Commit and push the changes to the repository.
#   - Update mock expectation JSON files with the latest commit SHA.
#   - Load the updated mock expectations into Mockserver.
#
# Usage:
#   ./00-app-sync.sh
#
# Steps performed:
#   - Updates the image tag in values.yaml from '0.1' to 'latest'.
#   - Commits and pushes the change to the simple-app repository.
#   - Retrieves the latest commit SHA.
#   - Updates the mock JSON files with the new commit SHA.
#   - Loads the updated expectations into Mockserver.
# -----------------------------------------------------------------------------
sleep 2
OS_TYPE=$(uname)
cd ../../setup/simple-app
if [ "$OS_TYPE" = "Linux" ]; then
    sed -i 's/0.1/latest/g' values.yaml
else 
    sed -i '' 's/0.1/latest/g' values.yaml
fi
git add --a
git commit -m "update values.yaml"
git push

srcCommitSha=$(git rev-parse HEAD)
## update commit sha for dev app
if [ "$OS_TYPE" = "Linux" ]; then
    sed -i "s/source-commit-sha/$srcCommitSha/g" ../../promotion/01-git-commit/00-app-sync.json
## update commit sha for prod app
    sed -i "s/source-commit-sha/$srcCommitSha/g" ../../promotion/01-git-commit/01-app-promote.json
else 
    sed -i '' "s/source-commit-sha/$srcCommitSha/g" ../../promotion/01-git-commit/00-app-sync.json
## update commit sha for prod app
    sed -i '' "s/source-commit-sha/$srcCommitSha/g" ../../promotion/01-git-commit/01-app-promote.json
fi

sleep 5
curl -i -X PUT http://127.0.0.1:1080/mockserver/expectation  --data-binary "@../../promotion/01-git-commit/00-app-sync.json"
