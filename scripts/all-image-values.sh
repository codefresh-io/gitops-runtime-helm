MYDIR=$(dirname $0)

$MYDIR/output-calculated-values.sh /tmp/gitops-runtime-values.yaml > /dev/null
python3 $MYDIR/helper-scripts/yaml-filter.py /tmp/gitops-runtime-values.yaml image.repository,image.registry,image.tag,argo-events.configs.nats.versions,argo-events.configs.jetstream.versions