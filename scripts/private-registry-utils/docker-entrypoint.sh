#!/bin/bash
export CHARTDIR="/chart"

if [[ "$EXTERNAL_ARGOCD" == "true" ]]; then
    export VALUESFILE="${CHARTDIR}/ci/values-external-argocd.yaml"
else
    export VALUESFILE="${CHARTDIR}/ci/values-all-images.yaml"
fi

./output-calculated-values.sh ./all-values.yaml
python3 ./helper-scripts/yaml-filter.py all-values.yaml image.repository,image.registry,image.tag,argo-events.configs.nats.versions,argo-events.configs.jetstream.versions,app-proxy.image-enrichment.config.images,-global.external-argo-cd > all-image-values.yaml
python3 private-registry-utils.py all-image-values.yaml $@
