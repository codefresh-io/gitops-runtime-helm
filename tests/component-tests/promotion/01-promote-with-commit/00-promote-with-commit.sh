#!/bin/bash
# -----------------------------------------------------------------------------
# Usage:
#   ./00-promote-with-commit.sh
#
# Steps performed:
#   - Loads the promote-with-commit mock expectations into Mockserver.
# -----------------------------------------------------------------------------
curl -i -X PUT http://127.0.0.1:1080/mockserver/expectation  --data-binary "@../../promotion/01-promote-with-commit/00-promote-with-commit.json"