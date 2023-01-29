# gitops-runtime-sandbox

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![AppVersion: v0.0.1](https://img.shields.io/badge/AppVersion-v0.0.1-informational?style=flat-square)

A Helm chart for Codefresh gitops runtime

**Homepage:** <https://github.com/codefresh-sandbox/gitops-runtime-charts>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| codefresh |  | <https://codefresh-io.github.io/> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://bitnami-labs.github.io/sealed-secrets/ | sealed-secrets | 2.1.6 |
| https://chartmuseum.codefresh.io/codefresh-tunnel-client | tunnel-client(codefresh-tunnel-client) | 0.1.11 |
| https://codefresh-io.github.io/argo-helm | argo-cd | 5.7.0-2-CR-16709-init-app-proxy |
| https://codefresh-io.github.io/argo-helm | argo-events | 2.0.5-1-cf-init |
| https://codefresh-io.github.io/argo-helm | argo-rollouts | 2.22.1-1-cap-sw |
| https://codefresh-io.github.io/argo-helm | argo-workflows | 0.22.8-1-cf-init |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| app-proxy.affinity | object | `{}` |  |
| app-proxy.config.argoCdUsername | string | `"admin"` |  |
| app-proxy.config.argoWorkflowsInsecure | string | `"true"` |  |
| app-proxy.config.env | string | `"production"` |  |
| app-proxy.env | object | `{}` |  |
| app-proxy.fullnameOverride | string | `"cap-app-proxy"` |  |
| app-proxy.image.pullPolicy | string | `"IfNotPresent"` |  |
| app-proxy.image.repository | string | `"quay.io/codefresh/cap-app-proxy"` |  |
| app-proxy.image.tag | string | `"CR-16355-dummy-components"` |  |
| app-proxy.imagePullSecrets | list | `[]` |  |
| app-proxy.initContainer.command[0] | string | `"./init.sh"` |  |
| app-proxy.initContainer.env | object | `{}` |  |
| app-proxy.initContainer.image.pullPolicy | string | `"IfNotPresent"` |  |
| app-proxy.initContainer.image.repository | string | `"quay.io/codefresh/cap-app-proxy-init"` |  |
| app-proxy.initContainer.image.tag | string | `"CR-16355-dummy-components"` |  |
| app-proxy.initContainer.resources.limits.cpu | string | `"1"` |  |
| app-proxy.initContainer.resources.limits.memory | string | `"512Mi"` |  |
| app-proxy.initContainer.resources.requests.cpu | string | `"0.2"` |  |
| app-proxy.initContainer.resources.requests.memory | string | `"256Mi"` |  |
| app-proxy.livenessProbe.failureThreshold | int | `10` | Minimum consecutive failures for the [probe] to be considered failed after having succeeded |
| app-proxy.livenessProbe.initialDelaySeconds | int | `10` | Number of seconds after the container has started before [probe] is initiated |
| app-proxy.livenessProbe.periodSeconds | int | `10` | How often (in seconds) to perform the [probe] |
| app-proxy.livenessProbe.successThreshold | int | `1` | Minimum consecutive successes for the [probe] to be considered successful after having failed |
| app-proxy.livenessProbe.timeoutSeconds | int | `10` | Number of seconds after which the [probe] times out |
| app-proxy.nameOverride | string | `""` |  |
| app-proxy.nodeSelector | object | `{}` |  |
| app-proxy.podAnnotations | object | `{}` |  |
| app-proxy.podLabels | object | `{}` |  |
| app-proxy.podSecurityContext | object | `{}` |  |
| app-proxy.readinessProbe.failureThreshold | int | `3` | Minimum consecutive failures for the [probe] to be considered failed after having succeeded |
| app-proxy.readinessProbe.initialDelaySeconds | int | `10` | Number of seconds after the container has started before [probe] is initiated |
| app-proxy.readinessProbe.periodSeconds | int | `10` | How often (in seconds) to perform the [probe] |
| app-proxy.readinessProbe.successThreshold | int | `1` | Minimum consecutive successes for the [probe] to be considered successful after having failed |
| app-proxy.readinessProbe.timeoutSeconds | int | `10` | Number of seconds after which the [probe] times out |
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
| argo-cd.crds.install | bool | `false` |  |
| argo-cd.fullnameOverride | string | `"argo-cd"` |  |
| argo-events.crds.install | bool | `false` |  |
| argo-events.fullnameOverride | string | `"argo-events"` |  |
| argo-rollouts.controller.replicas | int | `1` |  |
| argo-rollouts.enabled | bool | `false` |  |
| argo-rollouts.fullnameOverride | string | `"argo-rollouts"` |  |
| argo-workflows.enabled | bool | `true` |  |
| argo-workflows.fullnameOverride | string | `"argo"` |  |
| event-reporters.events.argoCDServerServiceName | string | `nil` | Do not set this value unless you are totally sure you need to override ArgoCD service name. Otherwise, it is determinted by chart logic |
| event-reporters.events.argoCDServerServicePort | string | `nil` | Do not set this value unless you are totally sure you need to override ArgoCD service port. Otherwise, it is determinted by chart logic |
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
| global.codefresh | object | `{"accountId":"","apiEventsPath":"/2.0/api/events","iscRepo":"","url":"https://g.codefresh.io","userToken":{"secretKeyRef":{},"token":""}}` | Codefresh platform and account related settings |
| global.codefresh.accountId | string | `""` | Codefresh Account id |
| global.codefresh.apiEventsPath | string | `"/2.0/api/events"` | Events API endpoint URL suffix |
| global.codefresh.iscRepo | string | `""` | Internal shared config repository URL for this Codefresh account |
| global.codefresh.url | string | `"https://g.codefresh.io"` | URL of Codefresh platform |
| global.codefresh.userToken | object | `{"secretKeyRef":{},"token":""}` | User token. Used for runtime registration against the patform. One of token (for plain text value) or secretKeyRef must be provided. |
| global.codefresh.userToken.secretKeyRef | object | `{}` | secretKeyRef to an existing secret containing the token |
| global.codefresh.userToken.token | string | `""` | Token in plain text (A secret for this token will be created and managed by the chart) |
| global.runtime | object | `{"argoCDApplication":{"chartRepo":"https://chartmuseum-dev.codefresh.io/gitops-runtime-sandbox","chartVersion":"","enabled":false,"name":"codefresh-gitops-runtime"},"cluster":null,"eventBus":{"nats":{"native":{"auth":"token","containerTemplate":{"resources":{"limits":{"cpu":"500m","ephemeral-storage":"2Gi","memory":"4Gi"},"requests":{"cpu":"200m","ephemeral-storage":"2Gi","memory":"1Gi"}}},"maxPayload":"4MB","replicas":3}}},"eventBusName":"codefresh-eventbus","ingress":{"annotations":{},"className":"nginx","enabled":true,"hosts":[],"tls":{}},"name":null}` | Runtime level settings |
| global.runtime.argoCDApplication | object | `{"chartRepo":"https://chartmuseum-dev.codefresh.io/gitops-runtime-sandbox","chartVersion":"","enabled":false,"name":"codefresh-gitops-runtime"}` | To be able to see the runtime in CodefreshUI, it is required to create and ArgoCD application that referneces it's components For that purpose we can create an ArgoApp that referneces the chart. |
| global.runtime.eventBus | object | `{"nats":{"native":{"auth":"token","containerTemplate":{"resources":{"limits":{"cpu":"500m","ephemeral-storage":"2Gi","memory":"4Gi"},"requests":{"cpu":"200m","ephemeral-storage":"2Gi","memory":"1Gi"}}},"maxPayload":"4MB","replicas":3}}}` | EventBus spec |
| global.runtime.eventBusName | string | `"codefresh-eventbus"` | Eventbus name |
| global.runtime.ingress | object | `{"annotations":{},"className":"nginx","enabled":true,"hosts":[],"tls":{}}` | Ingress settings |
| global.runtime.ingress.enabled | bool | `true` | Whether ingress is enabled. If disabled, tunnel-based runtime will be deployed |
| global.runtime.name | string | `nil` | Runtime name. Must be equal to namepsace in which it is intalled and unique per platform account |
| installer | object | `{"image":{"pullPolicy":"IfNotPresent","repository":"quay.io/codefresh/gitops-runtime-installer-sandbox","tag":"alpha2"}}` | Runtime installer - Used for running hooks and checks on the release |
| internal-router.affinity | object | `{}` |  |
| internal-router.env | object | `{}` | Environment variables - see values.yaml inside the chart for usage |
| internal-router.fullnameOverride | string | `"internal-router"` |  |
| internal-router.image.pullPolicy | string | `"IfNotPresent"` |  |
| internal-router.image.repository | string | `"nginx"` |  |
| internal-router.image.tag | string | `"1.22-alpine"` |  |
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
| sealed-secrets.fullnameOverride | string | `"sealed-secrets"` |  |
| sealed-secrets.image.registry | string | `"quay.io"` |  |
| sealed-secrets.image.repository | string | `"codefresh/sealed-secrets-controller"` |  |
| sealed-secrets.image.tag | string | `"v0.17.5"` |  |
| sealed-secrets.keyrenewperiod | string | `"720h"` |  |
| sealed-secrets.resources.limits.cpu | string | `"500m"` |  |
| sealed-secrets.resources.limits.memory | string | `"1Gi"` |  |
| sealed-secrets.resources.requests.cpu | string | `"200m"` |  |
| sealed-secrets.resources.requests.memory | string | `"512Mi"` |  |
| tunnel-client | object | `{"libraryMode":true,"tunnelServer":{"host":"register-tunnels.cf-cd.com","subdomainHost":"tunnels.cf-cd.com"}}` | Tunnel based runtime. Only relevant when runtime.ingress.enabled = false |
| tunnel-client.libraryMode | bool | `true` | Do not change this value! Breaks chart logic |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.9.1](https://github.com/norwoodj/helm-docs/releases/v1.9.1)
