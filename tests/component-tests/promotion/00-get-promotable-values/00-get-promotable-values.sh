#!/bin/bash
# -----------------------------------------------------------------------------
# Usage:
#   ./00-get-promotable-values.sh
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
git checkout dev

if [ "$OS_TYPE" = "Linux" ]; then
    sed -i 's/latest/0.1/g' values.yaml
else 
    sed -i '' 's/latest/0.1/g' values.yaml
fi

git add --a
git commit -m "update values.yaml"
git push
srcCommitSha=$(git rev-parse origin/dev)
## update commit sha for dev app
if [ "$OS_TYPE" = "Linux" ]; then
    sed -i "s/source-commit-sha/$srcCommitSha/g" ../../promotion/00-get-promotable-values/00-get-promotable-values.json
else 
    sed -i '' "s/source-commit-sha/$srcCommitSha/g" ../../promotion/00-get-promotable-values/00-get-promotable-values.json
fi
sleep 5
curl -i -X PUT http://127.0.0.1:1080/mockserver/expectation  --data-binary "@../../promotion/00-get-promotable-values/00-get-promotable-values.json"