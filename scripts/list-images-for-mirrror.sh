MYDIR=$(dirname $0)
CHARTDIR="${MYDIR}/../charts/gitops-runtime"
VALUESFILE="${CHARTDIR}/ci/values-all-images.yaml"
helm dependency update $CHARTDIR > /dev/null
helm template --values $VALUESFILE $CHARTDIR | grep -E -i  ".*Image: " | awk -F ':' '{if ($2) printf "%s:%s\n", $2, $3}' | tr -d "\"|[:blank:]" | sort -u |uniq -i
# Current limitation - the image for argoexec is missing, since it's sent as a parameter in the command in the template, and it's hard to match it with a regex.