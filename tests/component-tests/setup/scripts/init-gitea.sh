#!/bin/bash
#-----------------------------------------------------------------------------
# init-gitea.sh - Initializes Gitea server and repositories for component tests
#
# This script automates the setup of a Gitea test environment for the Codefresh
# GitOps Operator component test suite. It creates a test user, generates a user
# token, updates the runtime values file with the token, creates test repositories,
# and pushes initial commits and branches.
#
# Usage:
#   ./init-gitea.sh
#
# Steps performed:
#   - Port-forwards the Gitea service to localhost:3000.
#   - Creates a test user via the Gitea API.
#   - Generates a user token and updates runtime.values.yaml.
#   - Creates 'isc' and 'simple-app' repositories.
#   - Clones, configures, and pushes initial commits to the repositories.
#   - Creates a 'dev' branch in the simple-app repository and updates values.
# -----------------------------------------------------------------------------
OS_TYPE=$(uname)
kubectl --namespace gitea port-forward svc/gitea-http 3000:3000 &
sleep 3
## create repo owner
response=$(curl --location 'http://127.0.0.1:3000/api/v1/admin/users' \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic Z2l0ZWFfYWRtaW46cjhzQThDUEhEOSFidDZk' \
--data-binary "@./setup/fixture/payloads/create-user.json")

owner=$(echo "$response" | jq -r '.login')

## create user token
response=$(curl --location "http://127.0.0.1:3000/api/v1/users/$owner/tokens" \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic dGVzdC1vd25lcjpwYXNzd29yZA==' \
--data-binary "@./setup/fixture/payloads/create-user-token.json")

token=$(echo "$response" | jq -r '.sha1')

if [ "$OS_TYPE" = "Linux" ]; then
    sed -i "s/gitea-token/$token/g" ./setup/values/runtime.values.yaml
else 
    sed -i '' "s/gitea-token/$token/g" ./setup/values/runtime.values.yaml
fi

## create isc repo
curl --location 'http://127.0.0.1:3000/api/v1/user/repos' \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $token" \
--data-binary "@./setup/fixture/payloads/create-repo-isc.json"

## create simple app repo
curl --location 'http://127.0.0.1:3000/api/v1/user/repos' \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $token" \
--data-binary "@./setup/fixture/payloads/create-repo-simple-app.json"

## clone simple-app repo and push initial commit
cd ./setup
git clone http://127.0.0.1:3000/$owner/simple-app.git
cd simple-app
git config user.name "test-owner"
git config user.email "test.owner@gmail.com"

git remote set-url origin http://$owner:$token@127.0.0.1:3000/$owner/simple-app.git
cp -R ./../fixture/simple-app/* .
git add --a
git commit -m "Initial commit"
git push

## create dev branch
git checkout -b dev
git config user.name "test-owner"
git config user.email "test.owner@gmail.com"
git push --set-upstream origin dev
cd ..

## clone codefresh-isc repo and push initial commit
git clone http://127.0.0.1:3000/$owner/codefresh-isc.git
cd codefresh-isc
git remote set-url origin http://$owner:$token@127.0.0.1:3000/$owner/codefresh-isc.git
cp -R ./../fixture/codefresh-isc/* .
git add --a
git commit -m "Initial commit"
git push
cd ..



