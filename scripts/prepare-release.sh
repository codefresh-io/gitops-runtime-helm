GITOPS_RUNTIME_REPO=codefresh-io/gitops-runtime-helm
APP_PROXY_REPO=codefresh-io/argo-platform

docker run \
    -w "/chart" \
    -v "$(pwd):/chart" \
    -e APP_PROXY_REPO=$APP_PROXY_REPO \
    -e GITOPS_RUNTIME_REPO=$GITOPS_RUNTIME_REPO \
    -e GITHUB_TOKEN=$(gh auth token) \
    -u $(id -u) \
    --rm \
    gitops-runtime-scripts:local /scripts/prepare-release.sh

docker run \
    -v "$(pwd):/helm-docs" \
    -u $(id -u) \
    --rm \
    jnorwood/helm-docs:v1.9.1
