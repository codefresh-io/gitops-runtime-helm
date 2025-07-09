#!/bin/bash
# -----------------------------------------------------------------------------
# dragAndDrop.sh - Loads drag-and-drop mock expectations for component tests
#
# This script loads mock expectations into the Mockserver for drag-and-drop
# scenarios in the Codefresh GitOps Operator component test suite.
#
# Usage:
#   ./dragAndDrop.sh
#
# Steps performed:
#   - Waits briefly to ensure Mockserver is ready.
#   - Loads drag-and-drop mock expectations from dragAndDrop.json.
# -----------------------------------------------------------------------------
sleep 2
curl -i -X PUT http://127.0.0.1:1080/mockserver/expectation  --data-binary "@./dragAndDrop.json"
