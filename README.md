# README

See official documentation here: https://codefresh.io/docs/docs/installation/gitops/hybrid-gitops-helm-installation/


## Upgrade to `charts/gitops-runtime` from an existing Codefresh CLI installation

Adopt any existing ArgoCD resources:

```
#!/usr/bin/env bash
RELEASE=<release name>
NAMESPACE=<namespace name>

for this in $(kubectl get crd -o name | grep argoproj.io); do
  kubectl label --overwrite ${this} app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ${this} meta.helm.sh/release-name=${RELEASE}
  kubectl annotate --overwrite ${this} meta.helm.sh/release-namespace=${NAMESPACE}
done;

for k8s_kind in all configmap secret endpoints service rolebinding role; do
  for this in $(kubectl get ${k8s_kind} -n ${NAMESPACE} -o name; do
    kubectl label --namespace ${NAMESPACE} --overwrite ${this} app.kubernetes.io/managed-by=Helm
    kubectl annotate --namespace ${NAMESPACE} --overwrite ${this} meta.helm.sh/release-name=${RELEASE}
    kubectl annotate --namespace ${NAMESPACE} --overwrite ${this} meta.helm.sh/release-namespace=${NAMESPACE}
  done;
done;
```
