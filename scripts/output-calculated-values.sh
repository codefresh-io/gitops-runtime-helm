#!/bin/bash
MYDIR=$(dirname $0)
CHARTDIR="${MYDIR}/../charts/gitops-runtime"
VALUESFILE="${CHARTDIR}/ci/ingressless-values.yaml"
OUTPUTFILE=$1
ALL_VALUES_TEMPLATE=$(cat <<-END
{{ .Values | toYaml }}
END
)

echo $ALL_VALUES_TEMPLATE > $CHARTDIR/templates/all-values.yaml
helm dependency update $CHARTDIR
helm template --values $VALUESFILE --show-only templates/all-values.yaml $CHARTDIR > $OUTPUTFILE
rm $CHARTDIR/templates/all-values.yaml