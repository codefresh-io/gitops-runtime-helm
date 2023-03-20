# gitops-runtime

![Version: 0.2.0-alpha-11](https://img.shields.io/badge/Version-0.2.0--alpha--11-informational?style=flat-square) ![AppVersion: v0.0.1](https://img.shields.io/badge/AppVersion-v0.0.1-informational?style=flat-square)

A Helm chart for Codefresh gitops runtime

**Homepage:** <https://github.com/codefresh-io/gitops-runtime-helm>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| codefresh |  | <https://codefresh-io.github.io/> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://bitnami-labs.github.io/sealed-secrets/ | sealed-secrets | 2.1.6 |
| https://chartmuseum.codefresh.io/codefresh-tunnel-client | tunnel-client(codefresh-tunnel-client) | 0.1.12 |
| https://codefresh-io.github.io/argo-helm | argo-cd | 5.16.0-2-cap-CR-16950 |
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
| app-proxy.config.logLevel | string | `"info"` | Log Level |
| app-proxy.config.skipGitPermissionValidation | string | `"false"` | Skit git permissions validation |
| app-proxy.env | object | `{}` |  |
| app-proxy.fullnameOverride | string | `"cap-app-proxy"` |  |
| app-proxy.image-enrichment | object | `{"config":{"clientHeartbeatIntervalInSeconds":5,"concurrencyCmKey":"imageReportExecutor","concurrencyCmName":"workflow-synchronization-semaphores","podGcStrategy":"OnWorkflowCompletion","ttlActiveInSeconds":900,"ttlAfterCompletionInSeconds":86400},"enabled":true,"serviceAccount":{"annotations":null,"create":true,"name":"codefresh-image-enrichment-sa"}}` | Image enrichment process configuration |
| app-proxy.image-enrichment.config | object | `{"clientHeartbeatIntervalInSeconds":5,"concurrencyCmKey":"imageReportExecutor","concurrencyCmName":"workflow-synchronization-semaphores","podGcStrategy":"OnWorkflowCompletion","ttlActiveInSeconds":900,"ttlAfterCompletionInSeconds":86400}` | Configurations for image enrichment workflow |
| app-proxy.image-enrichment.config.clientHeartbeatIntervalInSeconds | int | `5` | Client heartbeat interval in seconds for image enrichemnt workflow |
| app-proxy.image-enrichment.config.concurrencyCmKey | string | `"imageReportExecutor"` | The name of the key in the configmap to use as synchronization semaphore |
| app-proxy.image-enrichment.config.concurrencyCmName | string | `"workflow-synchronization-semaphores"` | The name of the configmap to use as synchronization semaphore, see https://argoproj.github.io/argo-workflows/synchronization/ |
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
| app-proxy.image.tag | string | `"CR-17702-fix-runtime-name-crash"` |  |
| app-proxy.imagePullSecrets | list | `[]` |  |
| app-proxy.initContainer.command[0] | string | `"./init.sh"` |  |
| app-proxy.initContainer.env | object | `{}` |  |
| app-proxy.initContainer.image.pullPolicy | string | `"IfNotPresent"` |  |
| app-proxy.initContainer.image.repository | string | `"quay.io/codefresh/cap-app-proxy-init"` |  |
| app-proxy.initContainer.image.tag | string | `"CR-17702-fix-runtime-name-crash"` |  |
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
| global.codefresh | object | `{"accountId":"","apiEventsPath":"/2.0/api/events","gitIntegration":{"provider":{"apiUrl":"https://api.github.com","name":"GITHUB"}},"url":"https://g.codefresh.io","userToken":{"secretKeyRef":{},"token":""}}` | Codefresh platform and account-related settings |
| global.codefresh.accountId | string | `""` | Codefresh Account ID. |
| global.codefresh.apiEventsPath | string | `"/2.0/api/events"` | Events API endpoint URL suffix. |
| global.codefresh.gitIntegration | object | `{"provider":{"apiUrl":"https://api.github.com","name":"GITHUB"}}` | Git integration for this runtime.  Requires the Git provider name and the provider's API URL. |
| global.codefresh.gitIntegration.provider | object | `{"apiUrl":"https://api.github.com","name":"GITHUB"}` | The Git provider to use. We currently support GitHub, GitLab, Bitbucket Server, and Bitbucket Cloud. |
| global.codefresh.gitIntegration.provider.apiUrl | string | `"https://api.github.com"` | Provider API URL. Example for GitHub, https://api.github.com. |
| global.codefresh.gitIntegration.provider.name | string | `"GITHUB"` | Name of the Git provider: BITBUCKET, BITBUCKET_SERVER, GITHUB, GITLAB |
| global.codefresh.url | string | `"https://g.codefresh.io"` | URL of Codefresh platform. |
| global.codefresh.userToken | object | `{"secretKeyRef":{},"token":""}` | User token. Used for runtime registration against the patform. One of token (for plain text value) or secretKeyRef must be provided. |
| global.codefresh.userToken.secretKeyRef | object | `{}` | User token that references an existing secret containing the token. |
| global.codefresh.userToken.token | string | `""` | User token in plain text. The chart creates and manages the secret for this token. |
| global.runtime | object | `{"cluster":"https://kubernetes.default.svc","eventBus":{"nats":{"native":{"auth":"token","containerTemplate":{"resources":{"limits":{"cpu":"500m","ephemeral-storage":"2Gi","memory":"4Gi"},"requests":{"cpu":"200m","ephemeral-storage":"2Gi","memory":"1Gi"}}},"maxPayload":"4MB","replicas":3}}},"eventBusName":"codefresh-eventbus","gitCredentials":{"password":{"secretKeyRef":{},"value":null},"username":"username"},"ingress":{"annotations":{},"className":"nginx","enabled":false,"hosts":[],"protocol":"https","tls":[]},"name":null}` | Runtime level settings |
| global.runtime.cluster | string | `"https://kubernetes.default.svc"` | Runtime cluster. Should not be changed. |
| global.runtime.eventBus | object | `{"nats":{"native":{"auth":"token","containerTemplate":{"resources":{"limits":{"cpu":"500m","ephemeral-storage":"2Gi","memory":"4Gi"},"requests":{"cpu":"200m","ephemeral-storage":"2Gi","memory":"1Gi"}}},"maxPayload":"4MB","replicas":3}}}` | EventBus spec |
| global.runtime.eventBusName | string | `"codefresh-eventbus"` | Eventbus name |
| global.runtime.gitCredentials | object | `{"password":{"secretKeyRef":{},"value":null},"username":"username"}` | Git credentials runtime. Runtime is not fully functional without those credentials. If not provided through the installation, they must be provided through the Codefresh UI. |
| global.runtime.gitCredentials.password | object | `{"secretKeyRef":{},"value":null}` | Password. If using GitHub token, please provide it here. |
| global.runtime.gitCredentials.password.secretKeyRef | object | `{}` | secretKeyReference for Git credentials password. Provide name and key fields. |
| global.runtime.gitCredentials.password.value | string | `nil` | Plain text password |
| global.runtime.gitCredentials.username | string | `"username"` | Username. Optional when using token in password. |
| global.runtime.ingress | object | `{"annotations":{},"className":"nginx","enabled":false,"hosts":[],"protocol":"https","tls":[]}` | Ingress settings |
| global.runtime.ingress.enabled | bool | `false` | Defines if ingress-based access mode is enabled for runtime. To use tunnel-based (ingressless) access mode, set to false. |
| global.runtime.ingress.hosts | list | `[]` | Hosts for runtime ingress. Note that Codefresh platform will always use the first host in the list to access the runtime. |
| global.runtime.ingress.protocol | string | `"https"` | The protocol that Codefresh platform will use to access the runtime ingress. Can be http or https. |
| global.runtime.name | string | `nil` | Runtime name. Must be identical to the namepsace in which it is intalled and must be unique per platform account. |
| installer | object | `{"image":{"pullPolicy":"IfNotPresent","repository":"quay.io/codefresh/gitops-runtime-installer","tag":""}}` | Runtime installer used for running hooks and checks on the release |
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
| sealed-secrets | object | `{"fullnameOverride":"sealed-secrets-controller","image":{"registry":"quay.io","repository":"codefresh/sealed-secrets-controller","tag":"v0.17.5"},"keyrenewperiod":"720h","resources":{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"200m","memory":"512Mi"}}}` | --------------------------------------------------------------------------------------------------------------------- |
| tunnel-client | object | `{"libraryMode":true,"tunnelServer":{"host":"register-tunnels.cf-cd.com","subdomainHost":"tunnels.cf-cd.com"}}` | Tunnel based runtime. Only relevant when runtime.ingress.enabled = false |
| tunnel-client.libraryMode | bool | `true` | Do not change this value! Breaks chart logic |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.9.1](https://github.com/norwoodj/helm-docs/releases/v1.9.1)
