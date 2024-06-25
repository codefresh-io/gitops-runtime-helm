#!/bin/bash
set -eu #x

declare -A DOC_TEMPLATES
DOC_TEMPLATES=(
    ["argo-cd"]="https://github.com/codefresh-io/argo-helm/blob/\(.name)-\(.version)/charts/\(.name)"
    ["argo-events"]="https://github.com/codefresh-io/argo-helm/blob/\(.name)-\(.version)/charts/\(.name)"
    ["argo-workflows"]="https://github.com/codefresh-io/argo-helm/blob/\(.name)-\(.version)/charts/\(.name)"
    ["argo-rollouts"]="https://github.com/codefresh-io/argo-helm/blob/\(.name)-\(.version)/charts/\(.name)"
    ["sealed-secrets"]="https://artifacthub.io/packages/helm/bitnami-labs/\(.name)/\(.version)?modal=values"
    ["codefresh-tunnel-client"]="https://github.com/codefresh-io/codefresh-tunnel-charts/blob/\(.name)-\(.version)-helm/codefresh-tunnel-client/values.yaml"
    ["codefresh-gitops-operator"]="https://github.com/codefresh-io/codefresh-gitops-operator/tree/\(.name)-\(.version)-helm/charts/codefresh-gitops-operator"
)

# Render doc links
declare -A DOC_LINKS
CHART_YAML=${CHART_DIR}/Chart.yaml
for chart in ${!DOC_TEMPLATES[@]}; do
    # render doc link
    link=$(cat ${CHART_YAML} \
            | yq ".dependencies[]
                | select(.name == \"${chart}\")
                | \"${DOC_TEMPLATES[$chart]}\""
            )
    # comment on alias instead of a name if present
    chart=$(cat ${CHART_YAML} \
            | yq ".dependencies[]
                | select(.name == \"${chart}\")
                | .alias // .name"
            )
    DOC_LINKS[$chart]=$link
done

# Update values.yaml
VALUES_YAML=${CHART_DIR}/values.yaml
for chart in ${!DOC_LINKS[@]}; do
    COMMENT="
---------------------------------------------------------------------------------------------------------------------
DOCS: ${DOC_LINKS[$chart]}
---------------------------------------------------------------------------------------------------------------------"
    yq -i "(.${chart} | key) head_comment=\"${COMMENT}\"" ${VALUES_YAML}
done
