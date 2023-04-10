MYDIR=$(dirname $0)
CHARTDIR="${MYDIR}/../charts/gitops-runtime"
VALUESFILE="${CHARTDIR}/ci/ingressless-values.yaml"
helm dependency update $CHARTDIR > /dev/null
helm template --values $VALUESFILE $CHARTDIR | grep -E -i  ".*Image: " | awk -F ':' '{if ($2) printf "%s:%s\n", $2, $3}' | tr -d "\"|[:blank:]" | sort -u |uniq -i