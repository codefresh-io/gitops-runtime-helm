# README

See official documentation here: https://codefresh.io/docs/docs/installation/gitops/hybrid-gitops-helm-installation/

## To adopt argoproj crds:

1. Make sure kubectl is on the runtime cluster context
2. Run `scripts/adopt-crds.sh  [runtime Helm release name] [Runtime Namespace]`

## Upgrade to `charts/gitops-runtime` from an existing Codefresh CLI installation

Adopt any additional ArgoCD resources:

```
#!/usr/bin/env bash
RELEASE=<release name>
NAMESPACE=<namespace name>

for k8s_kind in all configmap secret endpoints service rolebinding role; do
  for this in $(kubectl get ${k8s_kind} -n ${NAMESPACE} -o name; do
    kubectl label --namespace ${NAMESPACE} --overwrite ${this} app.kubernetes.io/managed-by=Helm
    kubectl annotate --namespace ${NAMESPACE} --overwrite ${this} meta.helm.sh/release-name=${RELEASE}
    kubectl annotate --namespace ${NAMESPACE} --overwrite ${this} meta.helm.sh/release-namespace=${NAMESPACE}
  done;
done;
```
