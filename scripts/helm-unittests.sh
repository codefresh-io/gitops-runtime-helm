#!/bin/bash
## Reference: https://github.com/norwoodj/helm-docs
set -eux
CHART_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "$CHART_DIR"

echo "Running Helm unittests"
docker run --entrypoint "/bin/sh" -it --rm -v $CHART_DIR/charts:/charts alpine/helm:3.19.0 -c 'helm plugin install https://github.com/helm-unittest/helm-unittest.git --version 1.0.1 && helm unittest /charts/gitops-runtime -f tests/external_argocd_test.yaml'
