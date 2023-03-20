# README

See official documentation here: https://codefresh.io/docs/docs/installation/gitops/hybrid-gitops-helm-installation/


## Upgrade to `charts/gitops-runtime` from an existing Codefresh CLI installation

To adopt argoproj crds:
1. Make sure kubectl is on the runtime cluster context
2. Run scripts/adopt-crds.sh <Runtime Release Name> <Runtime Namespace>
