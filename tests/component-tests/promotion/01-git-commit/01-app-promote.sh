#!/bin/bash
# -----------------------------------------------------------------------------
# 01-app-promote.sh - Loads app promotion mock expectations for component tests
#
# This script loads mock expectations into the Mockserver for the app promotion
# scenario in the Codefresh GitOps Operator component test suite.
#
# Usage:
#   ./01-app-promote.sh
#
# Steps performed:
#   - Loads the app promotion mock expectations from 01-app-promote.json into Mockserver.
# -----------------------------------------------------------------------------
curl -i -X PUT http://127.0.0.1:1080/mockserver/expectation  --data-binary "@../../promotion/01-git-commit/01-app-promote.json"
