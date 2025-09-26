## Codefresh gitops runtime
![Version: 0.0.0](https://img.shields.io/badge/Version-0.0.0-informational?style=flat-square) ![AppVersion: 0.1.72](https://img.shields.io/badge/AppVersion-0.1.72-informational?style=flat-square)

## Prerequisites

- Helm **3.11.0+**

## Get Chart Info

```console
helm show all oci://quay.io/codefresh/gitops-runtime
```
See [Use OCI-based registries](https://helm.sh/docs/topics/registries/)

## Codefresh official documentation:
Prior to running the installation please see the official documentation at: https://codefresh.io/docs/docs/installation/gitops/hybrid-gitops-helm-installation/

## Argo-workflows artifact and log storage
Codefresh provides a SaaS object storage based solution for Argo workflows logs storage. The chart deploys a configmap named `codefresh-workflows-log-store` with the repository configuration.
If you want to utilize the Codefresh SaaS solution for log storage for all workflows in the runtime please set the following values:

```yaml
argo-workflows:
  controller:
    workflowDefaults:
      spec:
        artifactRepositoryRef:
          configMap: codefresh-workflows-log-store
          key: codefresh-workflows-log-store
```

> [!WARNING]
> It's highly recommended to use your own artifact storage for data privacy reasons.
> Codefresh provided storage has a retention policy of 14 days and limitations on uploaded file sizes.
> Please refer to the official documentation for more details.

## Installation with External ArgoCD

If you want to use an existing ArgoCD installation, you can disable the built-in ArgoCD and configure the GitOps Runtime to use the external ArgoCD.
See the `values.yaml` example below:

```yaml
global:
  # -- Configuration for external ArgoCD
  # Should be used when `argo-cd.enabled` is set to false
  external-argo-cd:
    # -- ArgoCD server settings
    server:
      # -- Service name of the ArgoCD server
      svc: argocd
      # -- Port of the ArgoCD server
      port: 80
      # -- Set if Argo CD is running behind reverse proxy under subpath different from /
      # e.g.
      # rootpath: '/argocd'
      rootpath: ''
    redis:
      # -- Service name of the ArgoCD Redis
      svc: argocd-redis
      # -- Port of the ArgoCD Redis
      port: 6379
    repoServer:
      # -- Service name of the ArgoCD repo server
      svc: argocd-repo-server
      # -- Port of the ArgoCD repo server
      port: 8081

    # -- How GitOps Runtime should authenticate with ArgoCD
    auth:
      # -- Authentication type. Can be password or token
      type: password

      # If `auth.type=password` is set
      # -- ArgoCD username in plain text
      username: "admin"
      # -- ArgoCD password in plain text
      password: ""
      # -- ArgoCD password referenced by an existing secret
      passwordSecretKeyRef:
        name: argocd-initial-admin-secret
        key: password

      # If `auth.type=token` is set
      # -- ArgoCD token in plain text
      token: ""
      # -- ArgoCD token referenced by an existing secret
      tokenSecretKeyRef: {}
      # e.g:
      # tokenSecretKeyRef:
      #   name: argocd-token
      #   key: token

argo-cd:
  # -- Disable built-in ArgoCD
  enabled: false
```

⚠️ If `auth.type=password` is set, ArgoCd user must have `apiKey` capability enabled.

`argocd-cm` ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
data:
  accounts.admin: apiKey, login
  admin.enabled: "true"
```

## Installation with External Argo Rollouts

If you want to use an existing Argo Rollouts installation, you can disable the built-in Argo Rollouts and configure the GitOps Runtime to use the external Argo Rollouts.
See the `values.yaml` example below:

```yaml
global:
  # -- Configuration for external Argo Rollouts
  external-argo-rollouts:
    # -- Rollout reporter settings
    rollout-reporter:
      # -- Enable rollout reporter
      # Configuration is defined at .Values.event-reporters.rollout
      enabled: true

argo-rollouts:
  # -- Disable built-in Argo Rollouts
  enabled: false
```

## Using with private registries - Helper utility
The GitOps Runtime comprises multiple subcharts and container images. Subcharts also vary in values structure, making it difficult to override image specific values to use private registries.
We have created a helper utility to resolve this issue:
- The utility create values files in the correct structure, overriding the registry for each image. When installing the chart, you can then provide those values files to override all images.
- The utility also creates other files with data to help you identify and correctly mirror all the images.

#### Usage

The utility is packaged in a container image. Below are instructions on executing the utility using Docker:

```
docker run -v <output_dir>:/output quay.io/codefresh/gitops-runtime-private-registry-utils:0.0.0 <local_registry>
```
`output_dir` - is a local directory where the utility will output files. <br>
`local_registry` - is your local registry where you want to mirror the images to

The utility will output 4 files into the folder:
1. `image-list.txt` - is the list of all images used in this version of the chart. Those are the images that you need to mirror.
2. `image-mirror.csv` - is a csv file with 2 fields - source_image and target_image. source_image is the image with the original registry and target_image is the image with the private registry. Can be used as an input file for a mirroring script.
3. `values-images-no-tags.yaml` - a values file with all image values with the private registry **excluding tags**. If provided through --values to helm install/upgrade command - it will override all images to use the private registry.
4. `values-images-with-tags.yaml` - The same as 3 but with tags **included**.

For usage with external ArgoCD run the utility with `EXTERNAL_ARGOCD` environment variable set to `true`.
```
docker run -e EXTERNAL_ARGOCD=true  -v <output_dir>:/output quay.io/codefresh/gitops-runtime-private-registry-utils:0.0.0 <local_registry>
```

## Openshift

```yaml
internal-router:
  dnsService: dns-default
  dnsNamespace: openshift-dns
  clusterDomain: cluster.local

argo-cd:
  redis:
    securityContext:
      runAsUser: 1000680000 # Arbitrary user ID within allowed range

  openshift:
    enabled: true

argo-events:
  openshift: true

  webhook:
    port: 8443

sealed-secrets:
  podSecurityContext:
    enabled: false
  containerSecurityContext:
    enabled: false
```

## High Availability

This chart installs the non-HA version of GitOps Runtime by default. If you want to run GitOps Runtime in HA mode, you can use the example values below:

> **Warning:**
> You need at least 3 worker nodes for HA mode

### HA mode with autoscaling

```yaml
global:
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule

app-proxy:
  replicaCount: 2
  pdb:
    enabled: true
    minAvailable: 1
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app: cap-app-proxy

gitops-operator:
  replicaCount: 2
  pdb:
    enabled: true
    minAvailable: 1
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app: gitops-operator

internal-router:
  replicaCount: 2
  pdb:
    enabled: true
    minAvailable: 1
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app: internal-router

cf-argocd-extras:
  sourcesServer:
    hpa:
      enabled: true
      minReplicas: 2
    pdb:
      enabled: true
      minAvailable: 1
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app.kubernetes.io/component: sources-server
  eventReporter:
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app.kubernetes.io/component: event-reporter

argo-cd:
  redis-ha:
    enabled: true

  controller:
    replicas: 1

  server:
    autoscaling:
      enabled: true
      minReplicas: 2
    pdb:
      enabled: true
      minAvailable: 1

  repoServer:
    autoscaling:
      enabled: true
      minReplicas: 2
    pdb:
      enabled: true
      minAvailable: 1

  applicationSet:
    replicas: 2

argo-workflows:
  controller:
    replicas: 2
    pdb:
      enabled: true
      minAvailable: 1
  server:
    autoscaling:
      enabled: true
      minReplicas: 2
    pdb:
      enabled: true
      minAvailable: 1

event-reporters:
  workflow:
    sensor:
      replicas: 2
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: sensor-name
                    operator: In
                    values:
                      - workflow-reporter
              topologyKey: "kubernetes.io/hostname"
  rollout:
    sensor:
      replicas: 2
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: sensor-name
                    operator: In
                    values:
                      - rollout-reporter
              topologyKey: "kubernetes.io/hostname"
```

## Upgrading

### To 0.23.x

####  Affected values

- `.Values.gitops-operator.image` map has been changed to include `registry` field. Please migrate the values git below:

```yaml
# before
gitops-operator:
  image:
    repository: quay.io/codefresh/codefresh-gitops-operator
    tag: vX.Y.Z

# after
gitops-operator:
  image:
    registry: quay.io
    repository: codefresh/codefresh-gitops-operator
    tag: vX.Y.Z
```

### To 0.24.x

####  Affected values

- `.Values.redis`/`.Values.redis-ha`/`.Values.redis-secret-init` were added

```yaml
# Enabled standalone (single Deployment) Redis
redis:
  enabled: true

# Enabled Redis High Availability (StatefulSet with Proxy)
redis-ha:
  enabled: false
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| app-proxy.affinity | object | `{}` |  |
| app-proxy.config.argoCdUrl | string | `nil` | ArgoCD Url. determined by chart logic. Do not change unless you are certain you need to |
| app-proxy.config.argoCdUsername | string | `"admin"` | ArgoCD user to be used by app-proxy |
| app-proxy.config.argoWorkflowsInsecure | string | `"true"` |  |
| app-proxy.config.argoWorkflowsUrl | string | `nil` | Workflows server url. Determined by chart logic. Do not change unless you are certain you need to |
| app-proxy.config.clusterChunkSize | int | `50` | define cluster list size per request to report the cluster state to platform, e.g. if you have 90 clusters and set clusterChunkSize: 40, it means cron job will report cluster state to platform in 3 iterations (40,40,10) - reduce this value if you have a lot of clusters and the cron job is failing with payload too large error - use 0 to sync all clusters at once |
| app-proxy.config.cors | string | `"https://g.codefresh.io"` | Cors settings for app-proxy. This is the list of allowed domains for platform. |
| app-proxy.config.env | string | `"production"` |  |
| app-proxy.config.logLevel | string | `"info"` | Log Level |
| app-proxy.config.skipGitPermissionValidation | string | `"false"` | Skit git permissions validation |
| app-proxy.env | object | `{}` |  |
| app-proxy.extraVolumeMounts | list | `[]` | Extra volume mounts for main container |
| app-proxy.extraVolumes | list | `[]` | extra volumes |
| app-proxy.fullnameOverride | string | `"cap-app-proxy"` |  |
| app-proxy.image-enrichment | object | `{"config":{"clientHeartbeatIntervalInSeconds":5,"concurrencyCmKey":"imageReportExecutor","concurrencyCmName":"workflow-synchronization-semaphores","images":{"gitEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-git-info","tag":"1.1.16-main"},"jiraEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-jira-info","tag":"1.1.16-main"},"reportImage":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-report-image-info","tag":"1.1.16-main"}},"podGcStrategy":"OnWorkflowCompletion","ttlActiveInSeconds":900,"ttlAfterCompletionInSeconds":86400},"enabled":true,"serviceAccount":{"annotations":null,"create":true,"name":"codefresh-image-enrichment-sa"}}` | Image enrichment process configuration |
| app-proxy.image-enrichment.config | object | `{"clientHeartbeatIntervalInSeconds":5,"concurrencyCmKey":"imageReportExecutor","concurrencyCmName":"workflow-synchronization-semaphores","images":{"gitEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-git-info","tag":"1.1.16-main"},"jiraEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-jira-info","tag":"1.1.16-main"},"reportImage":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-report-image-info","tag":"1.1.16-main"}},"podGcStrategy":"OnWorkflowCompletion","ttlActiveInSeconds":900,"ttlAfterCompletionInSeconds":86400}` | Configurations for image enrichment workflow |
| app-proxy.image-enrichment.config.clientHeartbeatIntervalInSeconds | int | `5` | Client heartbeat interval in seconds for image enrichemnt workflow |
| app-proxy.image-enrichment.config.concurrencyCmKey | string | `"imageReportExecutor"` | The name of the key in the configmap to use as synchronization semaphore |
| app-proxy.image-enrichment.config.concurrencyCmName | string | `"workflow-synchronization-semaphores"` | The name of the configmap to use as synchronization semaphore, see https://argoproj.github.io/argo-workflows/synchronization/ |
| app-proxy.image-enrichment.config.images | object | `{"gitEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-git-info","tag":"1.1.16-main"},"jiraEnrichment":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-image-enricher-jira-info","tag":"1.1.16-main"},"reportImage":{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-report-image-info","tag":"1.1.16-main"}}` | Enrichemnt images |
| app-proxy.image-enrichment.config.images.reportImage | object | `{"registry":"quay.io","repository":"codefreshplugins/argo-hub-codefresh-csdp-report-image-info","tag":"1.1.16-main"}` | Report image enrichment task image |
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
| app-proxy.image.tag | string | `"1.3772.0"` |  |
| app-proxy.imagePullSecrets | list | `[]` |  |
| app-proxy.initContainer.command[0] | string | `"./init.sh"` |  |
| app-proxy.initContainer.env | object | `{}` |  |
| app-proxy.initContainer.extraVolumeMounts | list | `[]` | Extra volume mounts for init container |
| app-proxy.initContainer.image.pullPolicy | string | `"IfNotPresent"` |  |
| app-proxy.initContainer.image.repository | string | `"quay.io/codefresh/cap-app-proxy-init"` |  |
| app-proxy.initContainer.image.tag | string | `"1.3772.0"` |  |
| app-proxy.initContainer.resources.limits | object | `{}` |  |
| app-proxy.initContainer.resources.requests.cpu | string | `"0.2"` |  |
| app-proxy.initContainer.resources.requests.memory | string | `"256Mi"` |  |
| app-proxy.leader-elector.containerSecurityContext.allowPrivilegeEscalation | bool | `false` |  |
| app-proxy.leader-elector.image.registry | string | `"quay.io"` |  |
| app-proxy.leader-elector.image.repository | string | `"codefresh/leader-elector"` |  |
| app-proxy.leader-elector.image.tag | string | `"0.0.1"` |  |
| app-proxy.leader-elector.livenessProbe.failureThreshold | int | `10` |  |
| app-proxy.leader-elector.livenessProbe.initialDelaySeconds | int | `10` |  |
| app-proxy.leader-elector.livenessProbe.periodSeconds | int | `10` |  |
| app-proxy.leader-elector.livenessProbe.successThreshold | int | `1` |  |
| app-proxy.leader-elector.livenessProbe.timeoutSeconds | int | `10` |  |
| app-proxy.leader-elector.readinessProbe.failureThreshold | int | `3` |  |
| app-proxy.leader-elector.readinessProbe.initialDelaySeconds | int | `10` |  |
| app-proxy.leader-elector.readinessProbe.periodSeconds | int | `10` |  |
| app-proxy.leader-elector.readinessProbe.successThreshold | int | `1` |  |
| app-proxy.leader-elector.readinessProbe.timeoutSeconds | int | `10` |  |
| app-proxy.leader-elector.resources.limits.cpu | string | `"200m"` |  |
| app-proxy.leader-elector.resources.limits.memory | string | `"200Mi"` |  |
| app-proxy.leader-elector.resources.requests.cpu | string | `"100m"` |  |
| app-proxy.leader-elector.resources.requests.memory | string | `"100Mi"` |  |
| app-proxy.livenessProbe.failureThreshold | int | `10` | Minimum consecutive failures for the [probe] to be considered failed after having succeeded. |
| app-proxy.livenessProbe.initialDelaySeconds | int | `10` | Number of seconds after the container has started before [probe] is initiated. |
| app-proxy.livenessProbe.periodSeconds | int | `10` | How often (in seconds) to perform the [probe]. |
| app-proxy.livenessProbe.successThreshold | int | `1` | Minimum consecutive successes for the [probe] to be considered successful after having failed. |
| app-proxy.livenessProbe.timeoutSeconds | int | `10` | Number of seconds after which the [probe] times out. |
| app-proxy.nameOverride | string | `""` |  |
| app-proxy.nodeSelector | object | `{}` |  |
| app-proxy.pdb.enabled | bool | `false` | Enable PDB |
| app-proxy.pdb.maxUnavailable | string | `""` | Set number of pods that are unavailable after eviction as number or percentage |
| app-proxy.pdb.minAvailable | int | `1` | Set number of pods that are available after eviction as number or percentage |
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
| app-proxy.serviceMonitor.enabled | bool | `false` |  |
| app-proxy.serviceMonitor.labels | object | `{}` |  |
| app-proxy.serviceMonitor.name | string | `""` |  |
| app-proxy.tolerations | list | `[]` |  |
| argo-cd.applicationVersioning.enabled | bool | `true` | Enable application versioning |
| argo-cd.applicationVersioning.useApplicationConfiguration | bool | `true` | Extract application version based on ApplicationConfiguration CRD |
| argo-cd.configs.cm."accounts.admin" | string | `"apiKey,login"` |  |
| argo-cd.configs.cm."application.resourceTrackingMethod" | string | `"annotation+label"` |  |
| argo-cd.configs.cm."resource.customizations.actions.argoproj.io_Rollout" | string | `"mergeBuiltinActions: true\ndiscovery.lua: |\n  actions = {}\n  local fullyPromoted = obj.status.currentPodHash == obj.status.stableRS\n  actions[\"pause\"] = {[\"disabled\"] = fullyPromoted or obj.spec.paused == true}\n  actions[\"skip-current-step\"] = {[\"disabled\"] = obj.spec.strategy.canary == nil or obj.spec.strategy.canary.steps == nil or obj.status.currentStepIndex == table.getn(obj.spec.strategy.canary.steps)}\n  return actions\ndefinitions:\n- name: pause\n  action.lua: |\n    obj.spec.paused = true\n    return obj\n- name: skip-current-step\n  action.lua: |\n    if obj.status ~= nil then\n        if obj.spec.strategy.canary ~= nil and obj.spec.strategy.canary.steps ~= nil and obj.status.currentStepIndex < table.getn(obj.spec.strategy.canary.steps) then\n            if obj.status.pauseConditions ~= nil and table.getn(obj.status.pauseConditions) > 0 then\n                obj.status.pauseConditions = nil\n            end\n            obj.status.currentStepIndex = obj.status.currentStepIndex + 1\n        end\n    end\n    return obj\n"` |  |
| argo-cd.configs.cm."timeout.reconciliation" | string | `"20s"` |  |
| argo-cd.configs.params."application.namespaces" | string | `"cf-*"` |  |
| argo-cd.configs.params."server.insecure" | bool | `true` |  |
| argo-cd.crds.install | bool | `true` |  |
| argo-cd.enabled | bool | `true` |  |
| argo-cd.fullnameOverride | string | `"argo-cd"` |  |
| argo-events.configs.jetstream.versions[0].configReloaderImage | string | `"natsio/nats-server-config-reloader:0.19.1"` |  |
| argo-events.configs.jetstream.versions[0].metricsExporterImage | string | `"natsio/prometheus-nats-exporter:0.17.3"` |  |
| argo-events.configs.jetstream.versions[0].natsImage | string | `"nats:2.11.4"` |  |
| argo-events.configs.jetstream.versions[0].startCommand | string | `"/nats-server"` |  |
| argo-events.configs.jetstream.versions[0].version | string | `"latest"` |  |
| argo-events.configs.nats.versions[0].metricsExporterImage | string | `"natsio/prometheus-nats-exporter:0.16.0"` |  |
| argo-events.configs.nats.versions[0].natsStreamingImage | string | `"nats-streaming:0.25.6"` |  |
| argo-events.configs.nats.versions[0].version | string | `"0.22.1"` |  |
| argo-events.crds.install | bool | `false` |  |
| argo-events.fullnameOverride | string | `"argo-events"` |  |
| argo-rollouts.controller.replicas | int | `1` |  |
| argo-rollouts.enabled | bool | `true` |  |
| argo-rollouts.fullnameOverride | string | `"argo-rollouts"` |  |
| argo-rollouts.installCRDs | bool | `true` |  |
| argo-workflows.crds.install | bool | `true` | Install and upgrade CRDs |
| argo-workflows.enabled | bool | `true` |  |
| argo-workflows.executor.resources.requests.ephemeral-storage | string | `"10Mi"` |  |
| argo-workflows.fullnameOverride | string | `"argo"` |  |
| argo-workflows.mainContainer.resources.requests.ephemeral-storage | string | `"10Mi"` |  |
| argo-workflows.server.authModes | list | `["client"]` | auth-mode needs to be set to client to be able to see workflow logs from Codefresh UI |
| argo-workflows.server.baseHref | string | `"/workflows/"` | Do not change. Workflows UI is only accessed through internal router, changing this values will break routing to workflows native UI from Codefresh. |
| cf-argocd-extras | object | `{"eventReporter":{"affinity":{},"container":{"image":{"registry":"quay.io","repository":"codefresh/cf-argocd-extras","tag":"1556733"}},"enabled":true,"nodeSelector":{},"pdb":{"enabled":false,"maxUnavailable":"","minAvailable":"50%"},"resources":{"requests":{"cpu":"100m","memory":"128Mi"}},"serviceMonitor":{"main":{"enabled":false}},"tolerations":[]},"sourcesServer":{"affinity":{},"container":{"image":{"registry":"quay.io","repository":"codefresh/cf-argocd-extras","tag":"1556733"}},"enabled":true,"hpa":{"enabled":false,"maxReplicas":10,"minReplicas":1,"targetCPUUtilizationPercentage":70},"nodeSelector":{},"pdb":{"enabled":false,"maxUnavailable":"","minAvailable":"50%"},"resources":{"requests":{"cpu":"100m","memory":"128Mi"}},"tolerations":[]}}` | Codefresh extra services for ArgoCD |
| cf-argocd-extras.eventReporter.pdb.enabled | bool | `false` | Enable PDB for event-reporter |
| cf-argocd-extras.eventReporter.serviceMonitor.main.enabled | bool | `false` | Enable ServiceMonitor for event reporter |
| cf-argocd-extras.sourcesServer | object | `{"affinity":{},"container":{"image":{"registry":"quay.io","repository":"codefresh/cf-argocd-extras","tag":"1556733"}},"enabled":true,"hpa":{"enabled":false,"maxReplicas":10,"minReplicas":1,"targetCPUUtilizationPercentage":70},"nodeSelector":{},"pdb":{"enabled":false,"maxUnavailable":"","minAvailable":"50%"},"resources":{"requests":{"cpu":"100m","memory":"128Mi"}},"tolerations":[]}` | Sources server configuration |
| cf-argocd-extras.sourcesServer.hpa.enabled | bool | `false` | Enable HPA for sources server |
| cf-argocd-extras.sourcesServer.pdb.enabled | bool | `false` | Enable PDB for sources server |
| codefreshWorkflowLogStoreCM | object | `{"enabled":true,"endpoint":"gitops-workflow-logs.codefresh.io","insecure":false}` | Argo workflows logs storage on Codefresh platform settings. Don't change unless instructed by Codefresh support. |
| event-reporters.rollout.eventSource.affinity | object | `{}` |  |
| event-reporters.rollout.eventSource.nodeSelector | object | `{}` |  |
| event-reporters.rollout.eventSource.replicas | int | `1` |  |
| event-reporters.rollout.eventSource.resources | object | `{}` |  |
| event-reporters.rollout.eventSource.tolerations | list | `[]` |  |
| event-reporters.rollout.sensor.affinity | object | `{}` |  |
| event-reporters.rollout.sensor.atLeastOnce | bool | `true` | At Least Once |
| event-reporters.rollout.sensor.env | object | `{}` | Environment variables for sensor pods - add DEBUG_LOG: "true" to add debug level logs |
| event-reporters.rollout.sensor.logging | object | `{"enabled":false,"intervalSeconds":0}` | Set to true to enable logging. Set intervalSeconds to add logging interval to moderate log flow. |
| event-reporters.rollout.sensor.nodeSelector | object | `{}` |  |
| event-reporters.rollout.sensor.policy.status.allow[0] | int | `200` |  |
| event-reporters.rollout.sensor.policy.status.allow[1] | int | `201` |  |
| event-reporters.rollout.sensor.policy.status.allow[2] | int | `204` |  |
| event-reporters.rollout.sensor.policy.status.allow[3] | int | `400` |  |
| event-reporters.rollout.sensor.policy.status.allow[4] | int | `401` |  |
| event-reporters.rollout.sensor.policy.status.allow[5] | int | `404` |  |
| event-reporters.rollout.sensor.replicas | int | `1` |  |
| event-reporters.rollout.sensor.resources | object | `{}` |  |
| event-reporters.rollout.sensor.retryStrategy | object | `{"duration":0,"factor":1,"jitter":1,"steps":3}` | Retry strategy for events sent to Codefresh |
| event-reporters.rollout.sensor.retryStrategy.duration | int | `0` | The initial duration, use strings like "2s", "1m" |
| event-reporters.rollout.sensor.retryStrategy.factor | float | `1` | Duration is multiplied by factor each retry, if factor is not zero and steps limit has not been reached. Should not be negative |
| event-reporters.rollout.sensor.retryStrategy.jitter | int | `1` | The sleep between each retry is the duration plus an additional amount chosen uniformly at random from the interval between zero and `jitter * duration`. |
| event-reporters.rollout.sensor.retryStrategy.steps | int | `3` | Number of retries |
| event-reporters.rollout.sensor.tolerations | list | `[]` |  |
| event-reporters.rollout.serviceAccount.create | bool | `true` |  |
| event-reporters.workflow.eventSource.affinity | object | `{}` |  |
| event-reporters.workflow.eventSource.nodeSelector | object | `{}` |  |
| event-reporters.workflow.eventSource.replicas | int | `1` |  |
| event-reporters.workflow.eventSource.resources | object | `{}` |  |
| event-reporters.workflow.eventSource.tolerations | list | `[]` |  |
| event-reporters.workflow.sensor.affinity | object | `{}` |  |
| event-reporters.workflow.sensor.atLeastOnce | bool | `true` | At Least Once |
| event-reporters.workflow.sensor.env | object | `{}` | Environment variables for sensor pods - add DEBUG_LOG: "true" to add debug level logs |
| event-reporters.workflow.sensor.logging | object | `{"enabled":false,"intervalSeconds":0}` | Set to true to enable logging. Set intervalSeconds to add logging interval to moderate log flow. |
| event-reporters.workflow.sensor.nodeSelector | object | `{}` |  |
| event-reporters.workflow.sensor.policy.status.allow[0] | int | `200` |  |
| event-reporters.workflow.sensor.policy.status.allow[1] | int | `201` |  |
| event-reporters.workflow.sensor.policy.status.allow[2] | int | `204` |  |
| event-reporters.workflow.sensor.policy.status.allow[3] | int | `400` |  |
| event-reporters.workflow.sensor.policy.status.allow[4] | int | `401` |  |
| event-reporters.workflow.sensor.policy.status.allow[5] | int | `404` |  |
| event-reporters.workflow.sensor.replicas | int | `1` |  |
| event-reporters.workflow.sensor.resources | object | `{}` |  |
| event-reporters.workflow.sensor.retryStrategy | object | `{"duration":0,"factor":1,"jitter":1,"steps":3}` | Retry strategy for events sent to Codefresh |
| event-reporters.workflow.sensor.retryStrategy.duration | int | `0` | The initial duration, use strings like "2s", "1m" |
| event-reporters.workflow.sensor.retryStrategy.factor | float | `1` | Duration is multiplied by factor each retry, if factor is not zero and steps limit has not been reached. Should not be negative |
| event-reporters.workflow.sensor.retryStrategy.jitter | int | `1` | The sleep between each retry is the duration plus an additional amount chosen uniformly at random from the interval between zero and `jitter * duration`. |
| event-reporters.workflow.sensor.retryStrategy.steps | int | `3` | Number of retries |
| event-reporters.workflow.sensor.tolerations | list | `[]` |  |
| event-reporters.workflow.serviceAccount.create | bool | `true` |  |
| gitops-operator.affinity | object | `{}` |  |
| gitops-operator.config.commitStatusPollingInterval | string | `"10s"` | Commit status polling interval |
| gitops-operator.config.maxConcurrentReleases | int | `100` | Maximum number of concurrent releases being processed by the operator (this will not affect the number of releases being processed by the gitops runtime) |
| gitops-operator.config.promotionWrapperTemplate | string | `""` | An optional template for the promotion wrapper (empty default will use the embedded one) |
| gitops-operator.config.taskPollingInterval | string | `"10s"` | Task polling interval |
| gitops-operator.config.workflowMonitorPollingInterval | string | `"10s"` | Workflow monitor polling interval |
| gitops-operator.crds | object | `{"additionalLabels":{},"annotations":{},"install":true,"keep":false}` | Codefresh gitops operator crds |
| gitops-operator.crds.additionalLabels | object | `{}` | Additional labels for gitops operator CRDs |
| gitops-operator.crds.annotations | object | `{}` | Annotations on gitops operator CRDs |
| gitops-operator.crds.install | bool | `true` | Whether or not to install CRDs |
| gitops-operator.crds.keep | bool | `false` | Keep CRDs if gitops runtime release is uninstalled |
| gitops-operator.enabled | bool | `true` |  |
| gitops-operator.env.GITOPS_OPERATOR_VERSION | string | `"0.11.1"` |  |
| gitops-operator.fullnameOverride | string | `""` |  |
| gitops-operator.image.registry | string | `"quay.io"` | defaults |
| gitops-operator.image.repository | string | `"codefresh/codefresh-gitops-operator"` |  |
| gitops-operator.image.tag | string | `"18fcd09"` |  |
| gitops-operator.imagePullSecrets | list | `[]` |  |
| gitops-operator.nameOverride | string | `""` |  |
| gitops-operator.nodeSelector | object | `{}` |  |
| gitops-operator.pdb.enabled | bool | `false` |  |
| gitops-operator.pdb.maxUnavailable | string | `""` |  |
| gitops-operator.pdb.minAvailable | int | `1` |  |
| gitops-operator.podAnnotations | object | `{}` |  |
| gitops-operator.podLabels | object | `{}` |  |
| gitops-operator.replicaCount | int | `1` |  |
| gitops-operator.resources.limits | object | `{}` |  |
| gitops-operator.resources.requests.cpu | string | `"100m"` |  |
| gitops-operator.resources.requests.memory | string | `"128Mi"` |  |
| gitops-operator.serviceAccount.annotations | object | `{}` |  |
| gitops-operator.serviceAccount.create | bool | `true` |  |
| gitops-operator.serviceAccount.name | string | `"gitops-operator-controller-manager"` |  |
| gitops-operator.tolerations | list | `[]` |  |
| global.codefresh | object | `{"accountId":"","apiEventsPath":"/2.0/api/events","tls":{"caCerts":{"secret":{"annotations":{},"content":"","create":false,"key":"ca-bundle.crt"},"secretKeyRef":{}},"workflowPipelinesGitWebhooks":{"annotations":{},"certificates":{}}},"url":"https://g.codefresh.io","userToken":{"secretKeyRef":{},"token":""}}` | Codefresh platform and account-related settings |
| global.codefresh.accountId | string | `""` | Codefresh Account ID. |
| global.codefresh.apiEventsPath | string | `"/2.0/api/events"` | Events API endpoint URL suffix. |
| global.codefresh.tls.caCerts | object | `{"secret":{"annotations":{},"content":"","create":false,"key":"ca-bundle.crt"},"secretKeyRef":{}}` | Custom CA certificates bundle for platform access with ssl |
| global.codefresh.tls.caCerts.secret | object | `{"annotations":{},"content":"","create":false,"key":"ca-bundle.crt"}` | Chart managed secret for custom platform CA certificates |
| global.codefresh.tls.caCerts.secret.create | bool | `false` | Whether to create the secret. |
| global.codefresh.tls.caCerts.secret.key | string | `"ca-bundle.crt"` | The secret key that holds the ca bundle |
| global.codefresh.tls.caCerts.secretKeyRef | object | `{}` | Reference to existing secret |
| global.codefresh.tls.workflowPipelinesGitWebhooks | object | `{"annotations":{},"certificates":{}}` | Those will be merged with the certificats defined in argo-cd.configs.tls.certificates - so if the certificates are already provided for ArgoCD, there is no need to provide them again. |
| global.codefresh.url | string | `"https://g.codefresh.io"` | URL of Codefresh platform. |
| global.codefresh.userToken | object | `{"secretKeyRef":{},"token":""}` | User token. Used for runtime registration against the patform. One of token (for plain text value) or secretKeyRef must be provided. |
| global.codefresh.userToken.secretKeyRef | object | `{}` | User token that references an existing secret containing the token. |
| global.codefresh.userToken.token | string | `""` | User token in plain text. The chart creates and manages the secret for this token. |
| global.external-argo-cd | object | `{"auth":{"password":"","passwordSecretKeyRef":{"key":"password","name":"argocd-initial-admin-secret"},"token":"","tokenSecretKeyRef":{},"type":"password","username":"admin"},"repoServer":{"port":8081,"svc":"argocd-repo-server"},"server":{"port":80,"rootpath":"","svc":"argocd-server"}}` | Configuration for external ArgoCD Should be used when `argo-cd.enabled` is set to false |
| global.external-argo-cd.auth | object | `{"password":"","passwordSecretKeyRef":{"key":"password","name":"argocd-initial-admin-secret"},"token":"","tokenSecretKeyRef":{},"type":"password","username":"admin"}` | How GitOps Runtime should authenticate with ArgoCD |
| global.external-argo-cd.auth.password | string | `""` | ArgoCD password in plain text |
| global.external-argo-cd.auth.passwordSecretKeyRef | object | `{"key":"password","name":"argocd-initial-admin-secret"}` | ArgoCD password referenced by an existing secret |
| global.external-argo-cd.auth.token | string | `""` | ArgoCD token in plain text |
| global.external-argo-cd.auth.tokenSecretKeyRef | object | `{}` | ArgoCD token referenced by an existing secret |
| global.external-argo-cd.auth.type | string | `"password"` | Authentication type. Can be password or token |
| global.external-argo-cd.auth.username | string | `"admin"` | ArgoCD username in plain text |
| global.external-argo-cd.repoServer.port | int | `8081` | Port of the ArgoCD repo server |
| global.external-argo-cd.repoServer.svc | string | `"argocd-repo-server"` | Service name of the ArgoCD repo server |
| global.external-argo-cd.server | object | `{"port":80,"rootpath":"","svc":"argocd-server"}` | ArgoCD server settings |
| global.external-argo-cd.server.port | int | `80` | Port of the ArgoCD server |
| global.external-argo-cd.server.rootpath | string | `""` | Set if Argo CD is running behind reverse proxy under subpath different from / e.g. rootpath: '/argocd' |
| global.external-argo-cd.server.svc | string | `"argocd-server"` | Service name of the ArgoCD server |
| global.external-argo-rollouts | object | `{"rollout-reporter":{"enabled":false}}` | Configuration for external Argo Rollouts |
| global.external-argo-rollouts.rollout-reporter | object | `{"enabled":false}` | Rollout reporter settings |
| global.external-argo-rollouts.rollout-reporter.enabled | bool | `false` | Enable or disable rollout reporter Configuration is defined at .Values.event-reporters.rollout |
| global.httpProxy | string | `""` | global HTTP_PROXY for all components |
| global.httpsProxy | string | `""` | global HTTPS_PROXY for all components |
| global.noProxy | string | `""` | global NO_PROXY for all components |
| global.nodeSelector | object | `{}` | Global nodeSelector for all components |
| global.runtime | object | `{"cluster":"https://kubernetes.default.svc","codefreshHosted":false,"eventBus":{"annotations":{},"jetstream":{"affinity":{},"containerTemplate":{"resources":{"limits":{"cpu":"500m","ephemeral-storage":"2Gi","memory":"4Gi"},"requests":{"cpu":"200m","ephemeral-storage":"2Gi","memory":"1Gi"}}},"maxPayload":"4MB","metadata":{"labels":{"app.kubernetes.io/name":"codefresh-eventbus"}},"nodeSelector":{},"replicas":3,"tolerations":[],"version":"latest"},"name":"","nats":{"native":{"affinity":{},"auth":"token","containerTemplate":{"resources":{"limits":{"cpu":"500m","ephemeral-storage":"2Gi","memory":"4Gi"},"requests":{"cpu":"200m","ephemeral-storage":"2Gi","memory":"1Gi"}}},"maxPayload":"4MB","metadata":{"labels":{"app.kubernetes.io/name":"codefresh-eventbus"}},"nodeSelector":{},"replicas":3,"tolerations":[]}},"pdb":{"enabled":true,"minAvailable":2},"type":"nats"},"gitCredentials":{"password":{"secretKeyRef":{},"value":null},"username":"username"},"ingress":{"annotations":{},"className":"nginx","enabled":false,"hosts":[],"labels":{},"protocol":"https","skipValidation":false,"tls":[]},"ingressUrl":"","isConfigurationRuntime":false,"name":null}` | Runtime level settings |
| global.runtime.cluster | string | `"https://kubernetes.default.svc"` | Runtime cluster. Should not be changed. |
| global.runtime.codefreshHosted | bool | `false` | Defines whether this is a Codefresh hosted runtime. Should not be changed. |
| global.runtime.eventBus | object | `{"annotations":{},"jetstream":{"affinity":{},"containerTemplate":{"resources":{"limits":{"cpu":"500m","ephemeral-storage":"2Gi","memory":"4Gi"},"requests":{"cpu":"200m","ephemeral-storage":"2Gi","memory":"1Gi"}}},"maxPayload":"4MB","metadata":{"labels":{"app.kubernetes.io/name":"codefresh-eventbus"}},"nodeSelector":{},"replicas":3,"tolerations":[],"version":"latest"},"name":"","nats":{"native":{"affinity":{},"auth":"token","containerTemplate":{"resources":{"limits":{"cpu":"500m","ephemeral-storage":"2Gi","memory":"4Gi"},"requests":{"cpu":"200m","ephemeral-storage":"2Gi","memory":"1Gi"}}},"maxPayload":"4MB","metadata":{"labels":{"app.kubernetes.io/name":"codefresh-eventbus"}},"nodeSelector":{},"replicas":3,"tolerations":[]}},"pdb":{"enabled":true,"minAvailable":2},"type":"nats"}` | Runtime eventbus |
| global.runtime.eventBus.annotations | object | `{}` | Annotations on EventBus resource |
| global.runtime.eventBus.name | string | `""` | Eventbus name |
| global.runtime.eventBus.pdb | object | `{"enabled":true,"minAvailable":2}` | Pod disruption budget for the eventbus |
| global.runtime.eventBus.pdb.minAvailable | int | `2` | Minimum number of available eventbus pods. For eventbus to stay functional the majority of its replicas should always be available. |
| global.runtime.gitCredentials | object | `{"password":{"secretKeyRef":{},"value":null},"username":"username"}` | Git credentials runtime. Runtime is not fully functional without those credentials. If not provided through the installation, they must be provided through the Codefresh UI. |
| global.runtime.gitCredentials.password | object | `{"secretKeyRef":{},"value":null}` | Password. If using GitHub token, please provide it here. |
| global.runtime.gitCredentials.password.secretKeyRef | object | `{}` | secretKeyReference for Git credentials password. Provide name and key fields. |
| global.runtime.gitCredentials.password.value | string | `nil` | Plain text password |
| global.runtime.gitCredentials.username | string | `"username"` | Username. Optional when using token in password. |
| global.runtime.ingress | object | `{"annotations":{},"className":"nginx","enabled":false,"hosts":[],"labels":{},"protocol":"https","skipValidation":false,"tls":[]}` | Ingress settings |
| global.runtime.ingress.enabled | bool | `false` | Defines if ingress-based access mode is enabled for runtime. To use tunnel-based (ingressless) access mode, set to false. |
| global.runtime.ingress.hosts | list | `[]` | Hosts for runtime ingress. Note that Codefresh platform will always use the first host in the list to access the runtime. |
| global.runtime.ingress.protocol | string | `"https"` | The protocol that Codefresh platform will use to access the runtime ingress. Can be http or https. |
| global.runtime.ingress.skipValidation | bool | `false` | if set to true, the pre-install hook will validate the existance of appropriate values, but *will not* attempt to make a web request to the ingress host |
| global.runtime.ingressUrl | string | `""` | Explicit url for runtime ingress. Provide this value only if you don't want the chart to create and ingress (global.runtime.ingress.enabled=false) and tunnel-client is not used (tunnel-client.enabled=false) |
| global.runtime.isConfigurationRuntime | bool | `false` | is the runtime set as a "configuration runtime". |
| global.runtime.name | string | `nil` | Runtime name. Must be unique per platform account. |
| global.tolerations | list | `[]` | Global tolerations for all components |
| installer | object | `{"affinity":{},"argoCdVersionCheck":{"argoServerLabels":{"app.kubernetes.io/component":"server","app.kubernetes.io/part-of":"argocd"}},"image":{"pullPolicy":"IfNotPresent","repository":"quay.io/codefresh/gitops-runtime-installer","tag":""},"nodeSelector":{},"skipUsageValidation":false,"skipValidation":false,"tolerations":[]}` | Runtime installer used for running hooks and checks on the release |
| installer.skipUsageValidation | bool | `false` | if set to true, pre-install hook will *not* run |
| installer.skipValidation | bool | `false` | if set to true, pre-install hook will *not* run |
| internal-router.affinity | object | `{}` |  |
| internal-router.clusterDomain | string | `"cluster.local"` |  |
| internal-router.dnsNamespace | string | `"kube-system"` |  |
| internal-router.dnsService | string | `"kube-dns"` |  |
| internal-router.env | object | `{}` | Environment variables - see values.yaml inside the chart for usage |
| internal-router.fullnameOverride | string | `"internal-router"` |  |
| internal-router.image.pullPolicy | string | `"IfNotPresent"` |  |
| internal-router.image.repository | string | `"docker.io/nginxinc/nginx-unprivileged"` |  |
| internal-router.image.tag | string | `"1.29-alpine3.22"` |  |
| internal-router.imagePullSecrets | list | `[]` |  |
| internal-router.ipv6 | object | `{"enabled":false}` | For ipv6 enabled clusters switch ipv6 enabled to true |
| internal-router.nameOverride | string | `""` |  |
| internal-router.nodeSelector | object | `{}` |  |
| internal-router.pdb.enabled | bool | `false` | Enable PDB |
| internal-router.pdb.maxUnavailable | string | `""` | Set number of pods that are unavailable after eviction as number or percentage |
| internal-router.pdb.minAvailable | int | `1` | Set number of pods that are available after eviction as number or percentage |
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
| redis | object | `{"affinity":{},"enabled":true,"env":{},"envFrom":[],"extraArgs":[],"image":{"registry":"public.ecr.aws","repository":"docker/library/redis","tag":"8.2.1-alpine"},"imagePullSecrets":[],"livenessProbe":{"enabled":true,"failureThreshold":5,"initialDelaySeconds":30,"periodSeconds":15,"successThreshold":1,"timeoutSeconds":15},"metrics":{"enabled":true,"env":{},"envFrom":[],"image":{"registry":"ghcr.io","repository":"oliver006/redis_exporter","tag":"v1.72.1"},"livenessProbe":{"enabled":true,"failureThreshold":5,"initialDelaySeconds":30,"periodSeconds":15,"successThreshold":1,"timeoutSeconds":15},"readinessProbe":{"enabled":true,"failureThreshold":5,"initialDelaySeconds":30,"periodSeconds":15,"successThreshold":1,"timeoutSeconds":15},"resources":{},"serviceMonitor":{"enabled":false}},"nodeSelector":{},"pdb":{"annotations":{},"enabled":false,"labels":{},"maxUnavailable":"","minAvailable":1},"podAnnotations":{},"podLabels":{},"podSecurityContext":{},"readinessProbe":{"enabled":true,"failureThreshold":5,"initialDelaySeconds":30,"periodSeconds":15,"successThreshold":1,"timeoutSeconds":15},"resources":{},"securityContext":{},"service":{"annotations":{},"labels":{},"ports":{"metrics":{"port":9121,"targetPort":9121},"redis":{"port":6379,"targetPort":6379}},"type":"ClusterIP"},"serviceAccount":{"annotations":{},"create":true,"name":""},"tolerations":[],"topologySpreadConstraints":[]}` | Enable standalone redis deployment Will be replaced by redis-ha subchart when `redis-ha.enabled=true` |
| redis-ha.additionalAffinities | object | `{}` | Additional affinities to add to the Redis server pods. |
| redis-ha.affinity | string | `""` | Assign custom [affinity] rules to the Redis pods. |
| redis-ha.auth | bool | `true` | Configures redis-ha with AUTH |
| redis-ha.containerSecurityContext | object | See [values.yaml] | Redis HA statefulset container-level security context |
| redis-ha.enabled | bool | `false` | Enables the Redis HA subchart and disables the custom Redis single node deployment |
| redis-ha.existingSecret | string | `"gitops-runtime-redis"` | Existing Secret to use for redis-ha authentication. By default the redis-secret-init Job is generating this Secret. |
| redis-ha.exporter.enabled | bool | `false` | Enable Prometheus redis-exporter sidecar |
| redis-ha.exporter.image | string | `"ghcr.io/oliver006/redis_exporter"` | Repository to use for the redis-exporter |
| redis-ha.exporter.tag | string | `"v1.69.0"` | Tag to use for the redis-exporter |
| redis-ha.fullnameOverride | string | `"redis-ha"` | Full name of the Redis HA Resources |
| redis-ha.haproxy.additionalAffinities | object | `{}` | Additional affinities to add to the haproxy pods. |
| redis-ha.haproxy.affinity | string | `""` | Assign custom [affinity] rules to the haproxy pods. |
| redis-ha.haproxy.containerSecurityContext | object | See [values.yaml] | HAProxy container-level security context |
| redis-ha.haproxy.enabled | bool | `true` | Enabled HAProxy LoadBalancing/Proxy |
| redis-ha.haproxy.hardAntiAffinity | bool | `true` | Whether the haproxy pods should be forced to run on separate nodes. |
| redis-ha.haproxy.metrics.enabled | bool | `true` | HAProxy enable prometheus metric scraping |
| redis-ha.haproxy.tolerations | list | `[]` | [Tolerations] for use with node taints for haproxy pods. |
| redis-ha.hardAntiAffinity | bool | `true` | Whether the Redis server pods should be forced to run on separate nodes. |
| redis-ha.image.repository | string | `"public.ecr.aws/docker/library/redis"` | Redis repository |
| redis-ha.image.tag | string | `"8.2.1-alpine"` | Redis tag |
| redis-ha.persistentVolume.enabled | bool | `false` | Configures persistence on Redis nodes |
| redis-ha.redis.config | object | See [values.yaml] | Any valid redis config options in this section will be applied to each server (see `redis-ha` chart) |
| redis-ha.redis.config.save | string | `'""'` | Will save the DB if both the given number of seconds and the given number of write operations against the DB occurred. `""`  is disabled |
| redis-ha.redis.masterGroupName | string | `"gitops-runtime"` | Redis convention for naming the cluster group: must match `^[\\w-\\.]+$` and can be templated |
| redis-ha.tolerations | list | `[]` | [Tolerations] for use with node taints for Redis pods. |
| redis-ha.topologySpreadConstraints | object | `{"enabled":false,"maxSkew":"","topologyKey":"","whenUnsatisfiable":""}` | Assign custom [TopologySpreadConstraints] rules to the Redis pods. |
| redis-ha.topologySpreadConstraints.enabled | bool | `false` | Enable Redis HA topology spread constraints |
| redis-ha.topologySpreadConstraints.maxSkew | string | `""` (defaults to `1`) | Max skew of pods tolerated |
| redis-ha.topologySpreadConstraints.topologyKey | string | `""` (defaults to `topology.kubernetes.io/zone`) | Topology key for spread |
| redis-ha.topologySpreadConstraints.whenUnsatisfiable | string | `""` (defaults to `ScheduleAnyway`) | Enforcement policy, hard or soft |
| redis-secret-init | object | `{"affinity":{},"image":{"registry":"docker.io","repository":"alpine/kubectl","tag":"1.34.1"},"nodeSelector":{},"tolerations":[]}` | Enable hook job to create redis secret |
| redis.image | object | `{"registry":"public.ecr.aws","repository":"docker/library/redis","tag":"8.2.1-alpine"}` | Redis image |
| redis.metrics | object | `{"enabled":true,"env":{},"envFrom":[],"image":{"registry":"ghcr.io","repository":"oliver006/redis_exporter","tag":"v1.72.1"},"livenessProbe":{"enabled":true,"failureThreshold":5,"initialDelaySeconds":30,"periodSeconds":15,"successThreshold":1,"timeoutSeconds":15},"readinessProbe":{"enabled":true,"failureThreshold":5,"initialDelaySeconds":30,"periodSeconds":15,"successThreshold":1,"timeoutSeconds":15},"resources":{},"serviceMonitor":{"enabled":false}}` | Enable metrics sidecar |
| redis.metrics.serviceMonitor | object | `{"enabled":false}` | Enable a prometheus ServiceMonitor |
| redis.pdb | object | `{"annotations":{},"enabled":false,"labels":{},"maxUnavailable":"","minAvailable":1}` | Enabled Pod Disruption Budget for redis |
| redis.readinessProbe | object | `{"enabled":true,"failureThreshold":5,"initialDelaySeconds":30,"periodSeconds":15,"successThreshold":1,"timeoutSeconds":15}` | Probes configuration |
| redis.service | object | `{"annotations":{},"labels":{},"ports":{"metrics":{"port":9121,"targetPort":9121},"redis":{"port":6379,"targetPort":6379}},"type":"ClusterIP"}` | Service configuration |
| redis.serviceAccount | object | `{"annotations":{},"create":true,"name":""}` | Create ServiceAccount for redis |
| sealed-secrets | object | `{"fullnameOverride":"sealed-secrets-controller","image":{"registry":"quay.io","repository":"codefresh/sealed-secrets-controller","tag":"0.32.0"},"keyrenewperiod":"720h","resources":{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"200m","memory":"512Mi"}}}` | --------------------------------------------------------------------------------------------------------------------- |
| tunnel-client | object | `{"affinity":{},"enabled":true,"libraryMode":true,"nodeSelector":{},"tolerations":[],"tunnelServer":{"host":"register-tunnels.cf-cd.com","subdomainHost":"tunnels.cf-cd.com"}}` | Tunnel based runtime. Not supported for on-prem platform. In on-prem use ingress based runtimes. |
| tunnel-client.enabled | bool | `true` | Will only be used if global.runtime.ingress.enabled = false |
| tunnel-client.libraryMode | bool | `true` | Do not change this value! Breaks chart logic |
