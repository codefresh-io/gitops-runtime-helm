# README

See official documentation here: https://codefresh.io/docs/docs/installation/gitops/hybrid-gitops-helm-installation/


## To adopt argoproj crds:

1. Make sure kubectl is on the runtime cluster context
2. Run scripts/adopt-crds.sh  [runtime Helm release name] [Runtime Namespace]

## pre-install hook failure:

run
```shell
kubectl log jobs/validate-values -n ${NAMESPACE}
```
(use your selected namespace)  
the output should help find the error in the values file.
in order to install while skipping the values validation, install with `--set installer.skipValidation="true"` (or set it in values file)
