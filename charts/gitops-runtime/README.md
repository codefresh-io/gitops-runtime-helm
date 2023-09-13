## Codefresh gitops runtime
![Version: 0.2.16](https://img.shields.io/badge/Version-0.2.16-informational?style=flat-square) ![AppVersion: 0.1.34](https://img.shields.io/badge/AppVersion-0.1.34-informational?style=flat-square)

## Codefresh official documentation:
Prior to running the installation please see the official documentation at: https://codefresh.io/docs/docs/installation/gitops/hybrid-gitops-helm-installation/

## Using with private registries - Helper utility
The GitOps Runtime comprises multiple subcharts and container images. Subcharts also vary in values structure, making it difficult to override image specific values to use private registries.
We have created a helper utility to resolve this issue: 
- The utility create values files in the correct structure, overriding the registry for each image. When installing the chart, you can then provide those values files to override all images.
- The utility also creates other files with data to help you identify and correctly mirror all the images.

#### Usage

The utility is packaged in a container image. Below are instructions on executing the utility using Docker:

```
docker run -v <output_dir>:/output quay.io/codefresh/gitops-runtime-private-registry-utils:0.2.16 <local_registry>
```
`output_dir` - is a local directory where the utility will output files. <br>
`local_registry` - is your local registry where you want to mirror the images to

The utility will output 4 files into the folder:
1. `image-list.txt` - is the list of all images used in this version of the chart. Those are the images that you need to mirror.
2. `image-mirror.csv` - is a csv file with 2 fields - source_image and target_image. source_image is the image with the original registry and target_image is the image with the private registry. Can be used as an input file for a mirroring script.
3. `values-images-no-tags.yaml` - a values file with all image values with the private registry **excluding tags**. If provided through --values to helm install/upgrade command - it will override all images to use the private registry.
4. `values-images-with-tags.yaml` - The same as 3 but with tags **included**.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| app-proxy.affinity | object | `{}` |  |
| app-proxy.config.argoCdUrl | string | `nil` | ArgoCD Url. determined by chart logic. Do not change unless you are certain you need to |
| app-proxy.config.argoCdUsername | string | `"admin"` | ArgoCD user to be used by app-proxy |
| app-proxy.config.argoWorkflowsInsecure | string | `"true"` |  |
| app-proxy.config.argoWorkflowsUrl | string | `nil` | Workflows server url. Determined by chart logic. Do not change unless you are certain you need to |
| app-proxy.config.env | string | `"production"` |  |
| app-proxy.config.logLevel | string | `"info"` | Log Level |
| app-proxy.config.skipGitPermissionValidation | string | `"false"` | Skit git permissions validation |
| app-proxy.env | object | `{}` |  |
| app-proxy.extraVolumeMounts | list | `[]` | Extra volume mounts for main container |
| app-proxy.extraVolumes | list | `[]` | extra volumes |
| app-proxy.fullnameOverride | string | `"cap-app-proxy"` |  |
| app-proxy.image-enrichment | object | `{"config":{"clientHeartbeatIntervalInSeconds":5,"concurrencyCmKey":"imageReportExecutor","concurrencyCmName":"workflow-synchronization-semaphores","images":{"gitEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-git-info","tag":"1.1.10-main"},"jiraEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-jira-info","tag":"1.1.10-main"},"reportImage":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-report-image-info","tag":"1.1.10-main"}},"podGcStrategy":"OnWorkflowCompletion","ttlActiveInSeconds":900,"ttlAfterCompletionInSeconds":86400},"enabled":true,"serviceAccount":{"annotations":null,"create":true,"name":"codefresh-image-enrichment-sa"}}` | Image enrichment process configuration |
| app-proxy.image-enrichment.config | object | `{"clientHeartbeatIntervalInSeconds":5,"concurrencyCmKey":"imageReportExecutor","concurrencyCmName":"workflow-synchronization-semaphores","images":{"gitEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-git-info","tag":"1.1.10-main"},"jiraEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-jira-info","tag":"1.1.10-main"},"reportImage":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-report-image-info","tag":"1.1.10-main"}},"podGcStrategy":"OnWorkflowCompletion","ttlActiveInSeconds":900,"ttlAfterCompletionInSeconds":86400}` | Configurations for image enrichment workflow |
| app-proxy.image-enrichment.config.clientHeartbeatIntervalInSeconds | int | `5` | Client heartbeat interval in seconds for image enrichemnt workflow |
| app-proxy.image-enrichment.config.concurrencyCmKey | string | `"imageReportExecutor"` | The name of the key in the configmap to use as synchronization semaphore |
| app-proxy.image-enrichment.config.concurrencyCmName | string | `"workflow-synchronization-semaphores"` | The name of the configmap to use as synchronization semaphore, see https://argoproj.github.io/argo-workflows/synchronization/ |
| app-proxy.image-enrichment.config.images | object | `{"gitEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-git-info","tag":"1.1.10-main"},"jiraEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-jira-info","tag":"1.1.10-main"},"reportImage":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-report-image-info","tag":"1.1.10-main"}}` | Enrichemnt images |
| app-proxy.image-enrichment.config.images.reportImage | object | `{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-report-image-info","tag":"1.1.10-main"}` | Report image enrichment task image |
| app-proxy.image-enrichment.config.podGcStrategy | string | `"OnWorkflowCompletion"` | Pod grabage collection strategy. By default all pods will be deleted when the enrichment workflow completes. |
| app-proxy.image-enrichment.config.ttlActiveInSeconds | int | `900` | Maximum allowed runtime for the enrichment workflow |
| app-proxy.image-enrichment.config.ttlAfterCompletionInSeconds | int | `86400` | Number of seconds to live after completion |
| app-proxy.image-enrichment.enabled | bool | `true` | Enable or disable enrichment process. Please note that for enrichemnt, argo-workflows has to be enabled as well. |
| app-proxy.image-enrichment.serviceAccount | object | `{"annotations":null,"create":true,"name":"codefresh-image-enrichment-sa"}` | Service account that will be used for enrichemnt process |
| app-proxy.image-enrichment.serviceAccount.annotations | string | `nil` | Annotations on the service account |
| app-proxy.image-enrichment.serviceAccount.create | bool | `true` | Whether to create the service account or use an existing one |
| app-proxy.image-enrichment.serviceAccount.name | string | `"codefresh-image-enrichment-sa"` | Name of the service account to create or the name of the existing one to use |
| app-proxy.image.pullPolicy | string | `"IfNotPresent"` |  |
| app-proxy.image.repository | string | `"quay.io/codefresh/cap-app-proxy"` |  |
| app-proxy.image.tag | string | `"1.2411.2"` |  |
| app-proxy.imagePullSecrets | list | `[]` |  |
| app-proxy.initContainer.command[0] | string | `"./init.sh"` |  |
| app-proxy.initContainer.env | object | `{}` |  |
| app-proxy.initContainer.extraVolumeMounts | list | `[]` | Extra volume mounts for init container |
| app-proxy.initContainer.image.pullPolicy | string | `"IfNotPresent"` |  |
| app-proxy.initContainer.image.repository | string | `"quay.io/codefresh/cap-app-proxy-init"` |  |
| app-proxy.initContainer.image.tag | string | `"1.2411.2"` |  |
| app-proxy.initContainer.resources.limits.cpu | string | `"1"` |  |
| app-proxy.initContainer.resources.limits.memory | string | `"512Mi"` |  |
| app-proxy.initContainer.resources.requests.cpu | string | `"0.2"` |  |
| app-proxy.initContainer.resources.requests.memory | string | `"256Mi"` |  |
| app-proxy.livenessProbe.failureThreshold | int | `10` | Minimum consecutive failures for the [probe] to be considered failed after having succeeded. |
| app-proxy.livenessProbe.initialDelaySeconds | int | `10` | Number of seconds after the container has started before [probe] is initiated. |
| app-proxy.livenessProbe.periodSeconds | int | `10` | How often (in seconds) to perform the [probe]. |
| app-proxy.livenessProbe.successThreshold | int | `1` | Minimum consecutive successes for the [probe] to be considered successful after having failed. |
| app-proxy.livenessProbe.timeoutSeconds | int | `10` | Number of seconds after which the [probe] times out. |
| app-proxy.nameOverride | string | `""` |  |
| app-proxy.nodeSelector | object | `{}` |  |
| app-proxy.podAnnotations | object | `{}` |  |
| app-proxy.podLabels | object | `{}` |  |
| app-proxy.podSecurityContext | object | `{}` |  |
| app-proxy.readinessProbe.failureThreshold | int | `3` | Minimum consecutive failures for the [probe] to be considered failed after having succeeded. |
| app-proxy.readinessProbe.initialDelaySeconds | int | `10` | Number of seconds after the container has started before [probe] is initiated. |
| app-proxy.readinessProbe.periodSeconds | int | `10` | How often (in seconds) to perform the [probe]. |
| app-proxy.readinessProbe.successThreshold | int | `1` | Minimum consecutive successes for the [probe] to be considered successful after having failed. |
| app-proxy.readinessProbe.timeoutSeconds | int | `10` | Number of seconds after which the [probe] times out. |
| app-proxy.replicaCount | int | `1` |  |
| app-proxy.resources.limits.cpu | string | `"1500m"` |  |
| app-proxy.resources.limits.ephemeral-storage | string | `"6Gi"` |  |
| app-proxy.resources.limits.memory | string | `"1Gi"` |  |
| app-proxy.resources.requests.cpu | string | `"100m"` |  |
| app-proxy.resources.requests.ephemeral-storage | string | `"2Gi"` |  |
| app-proxy.resources.requests.memory | string | `"512Mi"` |  |
| app-proxy.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| app-proxy.service.port | int | `3017` |  |
| app-proxy.service.type | string | `"ClusterIP"` |  |
| app-proxy.serviceAccount.annotations | object | `{}` |  |
| app-proxy.serviceAccount.create | bool | `true` |  |
| app-proxy.serviceAccount.name | string | `"cap-app-proxy"` |  |
| app-proxy.tolerations | list | `[]` |  |
| argo-cd.configs.cm."accounts.admin" | string | `"apiKey,login"` |  |
| argo-cd.configs.cm."timeout.reconciliation" | string | `"20s"` |  |
| argo-cd.configs.params."server.insecure" | bool | `true` |  |
| argo-cd.crds.install | bool | `true` |  |
| argo-cd.fullnameOverride | string | `"argo-cd"` |  |
| argo-cd.notifications.bots.slack | string | `nil` |  |
| argo-events.crds.install | bool | `false` |  |
| argo-events.fullnameOverride | string | `"argo-events"` |  |
| argo-rollouts.controller.replicas | int | `1` |  |
| argo-rollouts.enabled | bool | `true` |  |
| argo-rollouts.fullnameOverride | string | `"argo-rollouts"` |  |
| argo-rollouts.installCRDs | bool | `true` |  |
| argo-workflows.crds.install | bool | `true` | Install and upgrade CRDs |
| argo-workflows.enabled | bool | `true` |  |
| argo-workflows.fullnameOverride | string | `"argo"` |  |
| event-reporters.events.argoCDServerServiceName | string | `nil` | LEAVE EMPTY and let the chart logic determine the name. Change only if you are totally sure you need to override ArgoCD service name. |
| event-reporters.events.argoCDServerServicePort | string | `nil` | LEAVE EMPTY and let the chart logic determine the name. Change only if you are totally sure you need to override ArgoCD service port. |
| event-reporters.events.eventSource.replicas | int | `1` |  |
| event-reporters.events.eventSource.resources | object | `{}` |  |
| event-reporters.events.sensor.replicas | int | `1` |  |
| event-reporters.events.sensor.resources | object | `{}` |  |
| event-reporters.events.serviceAccount.create | bool | `true` |  |
| event-reporters.rollout.eventSource.replicas | int | `1` |  |
| event-reporters.rollout.eventSource.resources | object | `{}` |  |
| event-reporters.rollout.sensor.replicas | int | `1` |  |
| event-reporters.rollout.sensor.resources | object | `{}` |  |
| event-reporters.rollout.serviceAccount.create | bool | `true` |  |
| event-reporters.workflow.eventSource.replicas | int | `1` |  |
| event-reporters.workflow.eventSource.resources | object | `{}` |  |
| event-reporters.workflow.sensor.replicas | int | `1` |  |
| event-reporters.workflow.sensor.resources | object | `{}` |  |
| event-reporters.workflow.serviceAccount.create | bool | `true` |  |
| global.codefresh | object | `{"accountId":"","apiEventsPath":"/2.0/api/events","tls":{"caCerts":{"secret":{"annotations":{},"content":"","create":false,"key":"ca-bundle.crt"},"secretKeyRef":{}},"workflowPipelinesGitWebhooks":{"annotatins":{},"certificates":{}}},"url":"https://g.codefresh.io","userToken":{"secretKeyRef":{},"token":""}}` | Codefresh platform and account-related settings |
| global.codefresh.accountId | string | `""` | Codefresh Account ID. |
| global.codefresh.apiEventsPath | string | `"/2.0/api/events"` | Events API endpoint URL suffix. |
| global.codefresh.tls.caCerts | object | `{"secret":{"annotations":{},"content":"","create":false,"key":"ca-bundle.crt"},"secretKeyRef":{}}` | Custom CA certificates bundle for platform access with ssl |
| global.codefresh.tls.caCerts.secret | object | `{"annotations":{},"content":"","create":false,"key":"ca-bundle.crt"}` | Chart managed secret for custom platform CA certificates |
| global.codefresh.tls.caCerts.secret.create | bool | `false` | Whether to create the secret. |
| global.codefresh.tls.caCerts.secret.key | string | `"ca-bundle.crt"` | The secret key that holds the ca bundle |
| global.codefresh.tls.caCerts.secretKeyRef | object | `{}` | Reference to existing secret |
| global.codefresh.tls.workflowPipelinesGitWebhooks | object | `{"annotatins":{},"certificates":{}}` | Those will be merged with the certificats defined in argo-cd.configs.tls.certificates - so if the certificates are already provided for ArgoCD, there is no need to provide them again. |
| global.codefresh.url | string | `"https://g.codefresh.io"` | URL of Codefresh platform. |
| global.codefresh.userToken | object | `{"secretKeyRef":{},"token":""}` | User token. Used for runtime registration against the patform. One of token (for plain text value) or secretKeyRef must be provided. |
| global.codefresh.userToken.secretKeyRef | object | `{}` | User token that references an existing secret containing the token. |
| global.codefresh.userToken.token | string | `""` | User token in plain text. The chart creates and manages the secret for this token. |
| global.runtime | object | `{"cluster":"https://kubernetes.default.svc","eventBus":{"name":"codefresh-eventbus","nats":{"native":{"auth":"token","containerTemplate":{"resources":{"limits":{"cpu":"500m","ephemeral-storage":"2Gi","memory":"4Gi"},"requests":{"cpu":"200m","ephemeral-storage":"2Gi","memory":"1Gi"}}},"maxPayload":"4MB","replicas":3}},"pdb":{"enabled":true,"minAvailable":2}},"gitCredentials":{"password":{"secretKeyRef":{},"value":null},"username":"username"},"ingress":{"annotations":{},"className":"nginx","enabled":false,"hosts":[],"protocol":"https","tls":[]},"ingressUrl":"","name":null}` | Runtime level settings |
| global.runtime.cluster | string | `"https://kubernetes.default.svc"` | Runtime cluster. Should not be changed. |
| global.runtime.eventBus.name | string | `"codefresh-eventbus"` | Eventbus name |
| global.runtime.eventBus.pdb | object | `{"enabled":true,"minAvailable":2}` | Pod disruption budget for the eventbus |
| global.runtime.eventBus.pdb.minAvailable | int | `2` | Minimum number of available eventbus pods. For eventbus to stay functional the majority of its replicas should always be available. |
| global.runtime.gitCredentials | object | `{"password":{"secretKeyRef":{},"value":null},"username":"username"}` | Git credentials runtime. Runtime is not fully functional without those credentials. If not provided through the installation, they must be provided through the Codefresh UI. |
| global.runtime.gitCredentials.password | object | `{"secretKeyRef":{},"value":null}` | Password. If using GitHub token, please provide it here. |
| global.runtime.gitCredentials.password.secretKeyRef | object | `{}` | secretKeyReference for Git credentials password. Provide name and key fields. |
| global.runtime.gitCredentials.password.value | string | `nil` | Plain text password |
| global.runtime.gitCredentials.username | string | `"username"` | Username. Optional when using token in password. |
| global.runtime.ingress | object | `{"annotations":{},"className":"nginx","enabled":false,"hosts":[],"protocol":"https","tls":[]}` | Ingress settings |
| global.runtime.ingress.enabled | bool | `false` | Defines if ingress-based access mode is enabled for runtime. To use tunnel-based (ingressless) access mode, set to false. |
| global.runtime.ingress.hosts | list | `[]` | Hosts for runtime ingress. Note that Codefresh platform will always use the first host in the list to access the runtime. |
| global.runtime.ingress.protocol | string | `"https"` | The protocol that Codefresh platform will use to access the runtime ingress. Can be http or https. |
| global.runtime.ingressUrl | string | `""` | Explicit url for runtime ingress. Provide this value only if you don't want the chart to create and ingress (global.runtime.ingress.enabled=false) and tunnel-client is not used (tunnel-client.enabled=false) |
| global.runtime.name | string | `nil` | Runtime name. Must be unique per platform account. |
| installer | object | `{"image":{"pullPolicy":"IfNotPresent","repository":"quay.io/codefresh/gitops-runtime-installer","tag":""},"skipValidation":false}` | Runtime installer used for running hooks and checks on the release |
| installer.skipValidation | bool | `false` | if set to true, pre-install hook will *not* run |
| internal-router.affinity | object | `{}` |  |
| internal-router.clusterDomain | string | `"cluster.local"` |  |
| internal-router.dnsNamespace | string | `"kube-system"` |  |
| internal-router.dnsService | string | `"kube-dns"` |  |
| internal-router.env | object | `{}` | Environment variables - see values.yaml inside the chart for usage |
| internal-router.fullnameOverride | string | `"internal-router"` |  |
| internal-router.image.pullPolicy | string | `"IfNotPresent"` |  |
| internal-router.image.repository | string | `"nginxinc/nginx-unprivileged"` |  |
| internal-router.image.tag | string | `"1.23-alpine"` |  |
| internal-router.imagePullSecrets | list | `[]` |  |
| internal-router.nameOverride | string | `""` |  |
| internal-router.nodeSelector | object | `{}` |  |
| internal-router.podAnnotations | object | `{}` |  |
| internal-router.podLabels | object | `{}` |  |
| internal-router.podSecurityContext | object | `{}` |  |
| internal-router.replicaCount | int | `1` |  |
| internal-router.resources.limits.cpu | string | `"1"` |  |
| internal-router.resources.limits.memory | string | `"256Mi"` |  |
| internal-router.resources.requests.cpu | string | `"0.2"` |  |
| internal-router.resources.requests.memory | string | `"128Mi"` |  |
| internal-router.routing | object | `{}` | Internal routing settings. Do not change this unless you are absolutely certain - the values are determined by chart's logic. |
| internal-router.securityContext | object | `{}` |  |
| internal-router.service.port | int | `80` |  |
| internal-router.service.type | string | `"ClusterIP"` |  |
| internal-router.serviceAccount.annotations | object | `{}` |  |
| internal-router.serviceAccount.create | bool | `true` |  |
| internal-router.serviceAccount.name | string | `""` |  |
| internal-router.tolerations | list | `[]` |  |
| sealed-secrets | object | `{"fullnameOverride":"sealed-secrets-controller","image":{"registry":"quay.io","repository":"codefresh/sealed-secrets-controller","tag":"v0.19.4"},"keyrenewperiod":"720h","resources":{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"200m","memory":"512Mi"}}}` | --------------------------------------------------------------------------------------------------------------------- |
| tunnel-client | object | `{"enabled":true,"libraryMode":true,"tunnelServer":{"host":"register-tunnels.cf-cd.com","subdomainHost":"tunnels.cf-cd.com"}}` | Tunnel based runtime. Not supported for on-prem platform. In on-prem use ingress based runtimes. |
| tunnel-client.enabled | bool | `true` | Will only be used if global.runtime.ingress.enabled = false |
| tunnel-client.libraryMode | bool | `true` | Do not change this value! Breaks chart logic |
