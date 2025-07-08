#!/bin/bash
# -----------------------------------------------------------------------------
# init-platform.sh - Initializes platform mocks for component tests
#
# This script sets up mock expectations in the Mockserver for platform and Gitea
# endpoints. It port-forwards the Mockserver service, then loads mock
# expectations from JSON files to simulate platform and Gitea API responses.
#
# Usage:
#   ./init-platform.sh
#
# Steps performed:
#   - Port-forwards the Mockserver service to localhost:1080.
#   - Loads platform and Gitea mock expectations into Mockserver.
# -----------------------------------------------------------------------------
sleep 2
kubectl -n mockserver port-forward svc/mockserver 1080:1080 &
sleep 2
curl -i -X PUT http://127.0.0.1:1080/mockserver/expectation  --data-binary "@./setup/mocks/platform-mocks.json"
curl -i -X PUT http://127.0.0.1:1080/mockserver/expectation  --data-binary "@./setup/mocks/gitea-mocks.json"
