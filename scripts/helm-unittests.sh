#!/bin/bash
## Reference: https://github.com/norwoodj/helm-docs
set -eux
CHART_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "$CHART_DIR"

echo "Running Helm unittests"
docker run -it --rm -v $CHART_DIR/charts:/charts helmunittest/helm-unittest:3.15.3-0.5.1 /charts/gitops-runtime
