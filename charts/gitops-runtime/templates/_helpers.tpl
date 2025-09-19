{{/* Validation for secretKeyRef to avoid conflicting secret names with secrets created by controllers */}}
{{- define "codefresh-gitops-runtime.secret-name-validation"}}
  {{- $reservedSecretNames := list "codefresh-token" }}
  {{- if has .name $reservedSecretNames }}
    {{- fail (printf "%s is a reserved name and is not allowed. Please use a different secret name" .name) }}
  {{- end }}
{{- end }}
{{/*
Expand the name of the chart.
*/}}
{{- define "codefresh-gitops-runtime.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "codefresh-gitops-runtime.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "codefresh-gitops-runtime.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "codefresh-gitops-runtime.labels" -}}
helm.sh/chart: {{ include "codefresh-gitops-runtime.chart" . }}
{{ include "codefresh-gitops-runtime.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: codefresh-gitops-runtime
{{- end }}

{{/*
Selector labels
*/}}
{{- define "codefresh-gitops-runtime.selectorLabels" -}}
app: "codefresh-gitops-runtime"
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "codefresh-gitops-runtime.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "codefresh-gitops-runtime.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "codefresh-gitops-runtime.installation-token-secret-name" }}
{{- print "codefresh-user-token" }}
{{- end }}

{{/*
Determine argocd server service name. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.server.servicename" -}}
{{/* For now use template from ArgoCD chart until better approach */}}
{{- template "argo-cd.server.fullname" (dict "Values" (get .Values "argo-cd") "Release" .Release ) }}
{{- end }}

{{/*
Determine argocd redis service name. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.redis.servicename" -}}
{{/* For now use template from ArgoCD chart until better approach */}}
{{- template "argo-cd.redis.fullname" (dict "Values" (get .Values "argo-cd") "Release" .Release ) }}
{{- end }}

{{/*
Determine argocd repo server service name. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.reposerver.servicename" -}}
{{/* For now use template from ArgoCD chart until better approach */}}
  {{- if and (index .Subcharts "argo-cd") }}
    {{- template "argo-cd.repoServer.fullname" (dict "Values" (get .Values "argo-cd") "Release" .Release ) }}
  {{- else }}
    {{- $repoServer := index .Values "global" "external-argo-cd" "repoServer" }}
    {{- $svc := required "ArgoCD is not enabled and .Values.global.external-argo-cd.repoServer.svc is not set" $repoServer.svc }}
    {{- printf "%s" $svc }}
  {{- end }}
{{- end }}

{{/*
Determine argocd argocd repo server port
*/}}
{{- define "codefresh-gitops-runtime.argocd.reposerver.serviceport" -}}
{{/* For now use template from ArgoCD chart until better approach */}}
  {{- if and (index .Subcharts "argo-cd") }}
    {{- index .Values "argo-cd" "repoServer" "service" "port" }}
  {{- else }}
    {{- $repoServer := index .Values "global" "external-argo-cd" "repoServer" }}
    {{- $port := required "ArgoCD is not enabled and .Values.global.external-argo-cd.repoServer.svc is not set" $repoServer.port }}
    {{- printf "%v" $port }}
  {{- end }}
{{- end }}


{{/*
Determine argocd repoServer url
*/}}
{{- define "codefresh-gitops-runtime.argocd.reposerver.url" -}}
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- if and (index .Values "argo-cd" "enabled") }}
  {{- $serviceName := include "codefresh-gitops-runtime.argocd.reposerver.servicename" . }}
  {{- $port := include "codefresh-gitops-runtime.argocd.reposerver.serviceport" . }}
  {{- printf "%s:%s" $serviceName $port }}
{{- else if and (index .Values "global" "external-argo-cd" "repoServer") }}
  {{- $repoServer := (index .Values "global" "external-argo-cd" "repoServer") }}
  {{- $svc := required "ArgoCD is not enabled and .Values.global.external-argo-cd.repoServer.svc is not set" $repoServer.svc }}
  {{- $port := required "ArgoCD is not enabled and .Values.global.external-argo-cd.repoServer.port is not set" $repoServer.port }}
  {{- printf "%s:%v" $svc $port }}
{{- else }}
  {{- fail "ArgoCD is not enabled and .Values.global.external-argo-cd.repoServer is not set" }}
{{- end }}
{{- end}}


{{/*
Determine argocd servicename. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.appcontroller.serviceAccountName" -}}
{{/* For now use template from ArgoCD chart until better approach */}}
{{- template "argo-cd.controllerServiceAccountName" (dict "Values" (get .Values "argo-cd") "Release" .Release ) }}
{{- end }}

{{/*
Determine rollouts name
*/}}
{{- define "codefresh-gitops-runtime.argo-rollouts.name" -}}
  {{- if and (index .Values "argo-rollouts" "enabled") }}
    {{/* For now use template from rollouts chart until better approach */}}
    {{- template "argo-rollouts.fullname" (dict "Values" (get .Values "argo-rollouts")) }}
  {{- else }}
    {{- printf "argo-rollouts" }}
  {{- end }}
{{- end }}


{{/*
Determine argocd server service port. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.server.serviceport" -}}
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- $port := 443 }}
{{- if hasKey $argoCDValues "configs" }}
  {{- if hasKey $argoCDValues.configs "params" }}
    {{- if hasKey $argoCDValues.configs.params "server.insecure" }}
      {{- if (get $argoCDValues.configs.params "server.insecure") }}
        {{- $port = 80 }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- print $port }}
{{- end}}

{{/*
Determine argocd redis service port. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.redis.serviceport" -}}
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- $port := $argoCDValues.redis.servicePort }}
{{- print $port }}
{{- end}}

{{/*
Determine argocd server url. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.server.url" -}}
  {{- if and (index .Values "argo-cd" "enabled") }}
    {{- $protocol := "https" }}
    {{- $port := include "codefresh-gitops-runtime.argocd.server.serviceport" . }}
    {{- if (eq $port "80") }}
      {{- $protocol = "http" }}
    {{- end }}
    {{- $url := include "codefresh-gitops-runtime.argocd.server.no-protocol-url" . }}
    {{- printf "%s://%s" $protocol $url }}
  {{- else if and (index .Values "global" "external-argo-cd" "server") }}
    {{- $argoCDSrv := (index .Values "global" "external-argo-cd" "server") }}
    {{- $protocol := "http" }}
    {{- $svc := required "ArgoCD is not enabled and .Values.global.external-argo-cd.server.svc is not set" $argoCDSrv.svc }}
    {{- $port := (required "ArgoCD is not enabled and .Values.global.external-argo-cd.server.port is not port" $argoCDSrv.port) | toString }}
    {{- $rootpath := (index .Values "global" "external-argo-cd" "server" "rootpath") }}
    {{- if and (eq $port "80") }}
      {{- printf "%s://%s%s" $protocol $svc $rootpath }}
    {{- else }}
      {{- printf "%s://%s:%s%s" $protocol $svc $port $rootpath }}
    {{- end }}
  {{- else }}
    {{- fail "ArgoCD is not enabled and .Values.global.external-argo-cd.server is not set" }}
  {{- end }}
{{- end}}

{{/*
Determine argocd server url witout the protocol. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.server.no-protocol-url" -}}
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- if and (index .Values "argo-cd" "enabled") }}
  {{- $serverName := include "codefresh-gitops-runtime.argocd.server.servicename" . }}
  {{- $port := include "codefresh-gitops-runtime.argocd.server.serviceport" . }}
  {{- $path := (get $argoCDValues.configs.params "server.rootpath") }}
  {{- printf "%s:%s%s" $serverName $port $path }}
{{- else if and (index .Values "global" "external-argo-cd" "server") }}
  {{- $argoCDSrv := (index .Values "global" "external-argo-cd" "server") }}
  {{- $svc := required "ArgoCD is not enabled and .Values.global.external-argo-cd.server.svc is not set" $argoCDSrv.svc }}
  {{- $port := required "ArgoCD is not enabled and .Values.global.external-argo-cd.server.port is not set" $argoCDSrv.port }}
  {{- $rootpath := (index .Values "global" "external-argo-cd" "server" "rootpath") }}
  {{- printf "%s:%v%s" $svc $port $rootpath }}
{{- else }}
  {{- fail "ArgoCD is not enabled and .Values.global.external-argo-cd.server is not set" }}
{{- end }}
{{- end}}

{{/*
Determine argocd server password.
*/}}
{{- define "codefresh-gitops-runtime.argocd.server.password" }}
  {{- if and (index .Values "argo-cd" "enabled") }}
valueFrom:
  secretKeyRef:
    name: argocd-initial-admin-secret
    key: password
  {{- else if and (eq (index .Values "global" "external-argo-cd" "auth" "type") "password") (index .Values "global" "external-argo-cd" "auth" "passwordSecretKeyRef") }}
valueFrom:
  secretKeyRef:
{{- index .Values "global" "external-argo-cd" "auth" "passwordSecretKeyRef" | toYaml | nindent 4 }}
  {{- else if and (eq (index .Values "global" "external-argo-cd" "auth" "type") "password") (index .Values "global" "external-argo-cd" "auth" "password") }}
valueFrom:
  secretKeyRef:
    name: gitops-runtime-argo-cd-password
    key: token
  {{- else if and (eq (index .Values "global" "external-argo-cd" "auth" "type") "token") (index .Values "global" "external-argo-cd" "auth" "token") }}
valueFrom:
  secretKeyRef:
    name: gitops-runtime-argo-cd-token
    key: token
  {{- else if and (eq (index .Values "global" "external-argo-cd" "auth" "type") "token") (index .Values "global" "external-argo-cd" "auth" "tokenSecretKeyRef") }}
valueFrom:
  secretKeyRef:
{{- index .Values "global" "external-argo-cd" "auth" "tokenSecretKeyRef" | toYaml | nindent 4 }}
    optional: true
  {{- else }}
{{ fail "ArgoCD is not enabled and .Values.global.external-argo-cd.auth.password or .Values.global.external-argo-cd.auth.passwordSecretKeyRef is not set" }}
  {{- end }}
{{- end }}


{{/*
Determine argocd token password.
*/}}
{{- define "codefresh-gitops-runtime.argocd.server.token" }}
  {{- if and (eq (index .Values "global" "external-argo-cd" "auth" "type") "token") (index .Values "global" "external-argo-cd" "auth" "tokenSecretKeyRef" "name") (index .Values "global" "external-argo-cd" "auth" "tokenSecretKeyRef" "key")}}
valueFrom:
  secretKeyRef:
{{- index .Values "global" "external-argo-cd" "auth" "tokenSecretKeyRef" | toYaml | nindent 4 }}
  {{- else if and (eq (index .Values "global" "external-argo-cd" "auth" "type") "token") (index .Values "global" "external-argo-cd" "auth" "token") }}
valueFrom:
  secretKeyRef:
    name: gitops-runtime-argo-cd-token
    key: token
  {{- else if or (eq (index .Values "global" "external-argo-cd" "auth" "type") "password") }}
valueFrom:
  secretKeyRef:
    name: argocd-token
    key: token
    optional: true
  {{- else }}
    {{ fail (printf "Invalid value for .Values.global.external-argo-cd.auth.type: %s. Allowed values are: [password token]" (index .Values "global" "external-argo-cd" "auth" "type")) }}
  {{- end }}
{{- end }}

{{/*
Determine argocd server password.
*/}}
{{- define "codefresh-gitops-runtime.argocd.server.username-env-var" }}
  {{- if and (index .Values "argo-cd" "enabled") }}
valueFrom:
  configMapKeyRef:
    name: cap-app-proxy-cm
    key: argoCdUsername
    optional: true
  {{- else if and (index .Values "global" "external-argo-cd" "auth" "usernameSecretKeyRef") }}
valueFrom:
  secretKeyRef:
{{- index .Values "global" "external-argo-cd" "auth" "usernameSecretKeyRef" | toYaml | nindent 4 }}
  {{- else if and (index .Values "global" "external-argo-cd" "auth" "username") }}
{{- printf "%s" (index .Values "global" "external-argo-cd" "auth" "username") }}
  {{- else }}
{{ fail "ArgoCD is not enabled and .Values.global.external-argo-cd.auth.username or .Values.global.external-argo-cd.auth.usernameSecretKeyRef is not set" }}
  {{- end }}
{{- end }}

{{/*
Determine argocd server password.
*/}}
{{- define "codefresh-gitops-runtime.argocd.server.username-cm" }}
  {{- if and (index .Values "argo-cd" "enabled") }}
    {{- printf "%s" (index .Values "app-proxy" "config" "argoCdUsername") }}
  {{- else if and (index .Values "global" "external-argo-cd" "auth" "username") }}
    {{- printf "%s" (index .Values "global" "external-argo-cd" "auth" "username") }}
  {{- else }}
    {{- fail "ArgoCD is not enabled and .Values.global.external-argo-cd.auth.username is not set" }}
  {{- end }}
{{- end }}

{{/*
Determine argocd redis url
*/}}
{{- define "codefresh-gitops-runtime.argocd.redis.url" -}}
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- if and (index .Values "argo-cd" "enabled") }}
  {{- $serviceName := include "codefresh-gitops-runtime.argocd.redis.servicename" . }}
  {{- $port := include "codefresh-gitops-runtime.argocd.redis.serviceport" . }}
  {{- printf "%s:%s" $serviceName $port }}
{{- else if and (index .Values "global" "external-argo-cd" "redis") }}
  {{- $redis := (index .Values "global" "external-argo-cd" "redis") }}
  {{- $svc := required "ArgoCD is not enabled and .Values.global.external-argo-cd.redis.svc is not set" $redis.svc }}
  {{- $port := required "ArgoCD is not enabled and .Values.global.external-argo-cd.redis.port is not set" $redis.port }}
  {{- printf "%s:%v" $svc $port }}
{{- else }}
  {{- fail "ArgoCD is not enabled and .Values.global.external-argo-cd.redis is not set" }}
{{- end }}
{{- end}}

{{/*
Determine argo worklofws server name
*/}}
{{- define "codefresh-gitops-runtime.argo-workflows.server.name" -}}
{{/* For now use template from argo worklow chart until better approach */}}
{{- template "argo-workflows.server.fullname" (dict "Values" (get .Values "argo-workflows")) }}
{{- end }}

{{/*
Determine argo workflows server url. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argo-workflows.server.url" -}}
{{- $protocol := "http" }}
{{- if index (get .Values "argo-workflows") "server" "secure" }}
{{- $protocol = "https" }}
{{- end -}}
{{/* For now use template from Argo workflows chart until better approach */}}
{{- printf "%s://%s:2746" $protocol (include "codefresh-gitops-runtime.argo-workflows.server.name" .) }}
{{- end }}

{{/*
Determine app proxy url. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.app-proxy.url" -}}
{{/* Using templates from app-proxy */}}
{{- printf "http://%s:%s" (include "cap-app-proxy.fullname" (dict "Values" (get .Values "app-proxy"))) (index (get .Values "app-proxy") "service" "port" | toString ) }}
{{- end }}

{{/*
Environemnt variable value of Codefresh installation token
*/}}
{{- define "codefresh-gitops-runtime.installation-token-env-var-value" -}}
  {{- if .Values.global.codefresh.userToken.token }}
valueFrom:
  secretKeyRef:
    name: {{ include "codefresh-gitops-runtime.installation-token-secret-name" . }}
    key: token
    optional: true
  {{- else if .Values.global.codefresh.userToken.secretKeyRef  }}
    {{- include "codefresh-gitops-runtime.secret-name-validation" .Values.global.codefresh.userToken.secretKeyRef }}
valueFrom:
  secretKeyRef:
  {{- .Values.global.codefresh.userToken.secretKeyRef | toYaml | nindent 4 }}
  {{- else }}
    {{- fail "global.codefresh.userToken is mandatory. Set token or secretKeyRef!" }}
  {{- end }}
{{- end }}


{{/*
Get ingress url for both tunnel based and ingress based runtimes
*/}}
{{- define "codefresh-gitops-runtime.ingress-url"}}
  {{- $supportedProtocols := list "http" "https" }}
    {{- if .Values.global.runtime.ingress.enabled }}
      {{- if has .Values.global.runtime.ingress.protocol $supportedProtocols }}
        {{- printf "%s://%s" .Values.global.runtime.ingress.protocol  (index .Values.global.runtime.ingress.hosts 0)}}
      {{- else }}
          {{ fail (printf "ERROR: Unsupported protocol %s for ingress. Only http and https supported" .Values.global.runtime.ingress.protocol)}}
      {{- end }}
    {{/* If tunnel client is enabled - ingress url is <accoundId>-<runtimename>.<tunnel-subdomain> */}}
    {{- else if index .Values "tunnel-client" "enabled" }}
      {{- $accoundId := required "global.codefresh.accountId is required for tunnel based runtime" .Values.global.codefresh.accountId }}
      {{- $runtimeName := required "global.runtime.name is required for tunnel based runtime" .Values.global.runtime.name }}
      {{- $tunnelPrefix := printf "%s-%s" .Values.global.codefresh.accountId .Values.global.runtime.name }}
      {{- $tunnelHost := index (get .Values "tunnel-client") "tunnelServer" "subdomainHost"}}
      {{- printf "https://%s.%s" $tunnelPrefix $tunnelHost }}
    {{- else }}
    {{/* If ingress is disabled and tunnel-client is disabled, the ingressHost must be explicitly defined in the values*/}}
      {{- if .Values.global.runtime.ingressUrl }}
          {{- if or (hasPrefix "http" .Values.global.runtime.ingressUrl) (hasPrefix "https" .Values.global.runtime.ingressUrl)}}
            {{- print .Values.global.runtime.ingressUrl }}
          {{- else }}
            {{- fail "ERROR: Only http and https are supported for global.runtime.ingressUrl"}}
          {{- end }}
      {{- else }}
        {{- fail "ERROR: When global.runtime.ingress.enabled is false and tunnel-client.enabled is false -  global.runtime.ingressUrl must be provided" }}
      {{- end }}
    {{- end }}
{{- end }}

{{/*
Output comma separated list of installed runtime components
*/}}
{{- define "codefresh-gitops-runtime.component-list"}}
  {{- $argoEvents := dict "name" "argo-events" "version" (get .Subcharts "argo-events").Chart.AppVersion }}
  {{- $sealedSecrets := dict "name" "sealed-secrets" "version" (get .Subcharts "sealed-secrets").Chart.AppVersion }}
  {{- $internalRouter := dict "name" "internal-router" "version" .Chart.AppVersion }}
  {{- $appProxy := dict "name" "app-proxy" "version" (index (get .Values "app-proxy") "image" "tag") }}
  {{- $argoApiGateway := dict "name" "argo-api-gateway" "version" (get .Values "argo-api-gateway").image.tag }}
  {{- $comptList := list $argoEvents $appProxy $sealedSecrets $internalRouter $argoApiGateway }}
{{- if and (index .Values "argo-cd" "enabled") }}
  {{- $argoCD := dict "name" "argocd" "version" (get .Subcharts "argo-cd").Chart.AppVersion }}
  {{- $comptList = append $comptList $argoCD }}
{{- end }}
  {{- if index (get .Values "argo-rollouts") "enabled" }}
    {{- $rolloutReporter := dict "name" "rollout-reporter" "version" .Chart.AppVersion }}
    {{- $argoRollouts := dict "name" "argo-rollouts" "version" (get .Subcharts "argo-rollouts").Chart.AppVersion }}
    {{- $comptList = append $comptList $argoRollouts }}
    {{- $comptList = append $comptList $rolloutReporter }}
  {{- end }}
  {{- if index (get .Values "argo-workflows") "enabled" }}
    {{- $workflowReporter := dict "name" "workflow-reporter" "version" .Chart.AppVersion }}
    {{- $argoWorkflows := dict "name" "argo-workflows" "version" (get .Subcharts "argo-workflows").Chart.AppVersion }}
    {{- $comptList = append $comptList $workflowReporter}}
    {{- $comptList = append $comptList $argoWorkflows }}
  {{- end }}
  {{- if and ( not .Values.global.runtime.ingress.enabled) (index .Values "tunnel-client" "enabled") }}
    {{- $tunnelClient := dict "name" "codefresh-tunnel-client" "version" (get .Subcharts "tunnel-client").Chart.AppVersion }}
    {{- $comptList = append $comptList $tunnelClient }}
  {{- end }}
  {{- if index (get .Values "gitops-operator") "enabled" }}
    {{- $gitopsOperator := dict "name" "gitops-operator" "version" (get .Values "gitops-operator").image.tag }}
    {{- $comptList = append $comptList $gitopsOperator }}
  {{- end }}
  {{- if not (index .Values "argo-cd" "enabled") }}
    {{- $eventReporter := dict "name" "event-reporter" "version" (index (get .Values "event-reporters") "runtime-reporter" "image" "tag") }}
    {{- $comptList = append $comptList $eventReporter }}
  {{- end }}
{{- $comptList | toYaml }}
{{- end }}

# ------------------------------------------------------------------------------------------------------------
# runtime git credentials
# ------------------------------------------------------------------------------------------------------------
{{- define "codefresh-gitops-runtime.runtime-gitcreds.password.default-secret-name" }}
{{- printf "%s-git-password" .Values.global.runtime.name }}
{{- end }}

{{- define "codefresh-gitops-runtime.runtime-gitcreds.password.secretname" }}
  {{- if .Values.global.runtime.gitCredentials.password.value}}
  {{- include "codefresh-gitops-runtime.runtime-gitcreds.password.default-secret-name" . }}
  {{- else if .Values.global.runtime.gitCredentials.password.secretKeyRef }}
    {{- if hasKey .Values.global.runtime.gitCredentials.password.secretKeyRef "name" }}
      {{- include "codefresh-gitops-runtime.secret-name-validation" .Values.global.runtime.gitCredentials.password.secretKeyRef }}
      {{- print .Values.global.runtime.gitCredentials.password.secretKeyRef.name }}
    {{- else }}
    {{ fail "secretKeyRef for global.runtime.gitCredentials.password illegal - must have name field"}}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "codefresh-gitops-runtime.runtime-gitcreds.password.secretkey" }}
  {{- if .Values.global.runtime.gitCredentials.password.value}}
  {{- print "password" }}
  {{- else if .Values.global.runtime.gitCredentials.password.secretKeyRef }}
    {{- if hasKey .Values.global.runtime.gitCredentials.password.secretKeyRef "key" }}
      {{- print .Values.global.runtime.gitCredentials.password.secretKeyRef.key }}
    {{- else }}
    {{ fail "secretKeyRef for global.runtime.gitCredentials.password illegal - must have key field"}}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "codefresh-gitops-runtime.runtime-gitcreds.password.env-var-value"}}
valueFrom:
  secretKeyRef:
    name: {{ include "codefresh-gitops-runtime.runtime-gitcreds.password.secretname" . }}
    key: {{ include "codefresh-gitops-runtime.runtime-gitcreds.password.secretkey" . }}
    optional: true
{{- end }}
# ------------------------------------------------------------------------------------------------------------

{{/*
Print proxy environment variables
*/}}
{{- define "codefresh-gitops-runtime.get-proxy-env-vars" -}}
  {{- if .Values.global.httpProxy }}
HTTP_PROXY: {{ .Values.global.httpProxy | quote }}
  {{- end }}
  {{- if .Values.global.httpsProxy }}
HTTPS_PROXY: {{ .Values.global.httpsProxy | quote }}
  {{- end }}
  {{- if .Values.global.noProxy }}
NO_PROXY: {{ .Values.global.noProxy | quote }}
  {{- end }}
{{- end -}}

{{- define "codefresh-gitops-runtime.eventbus.name" }}
  {{- $eventBusName := "" }}
  {{- $eventBusType := .type }}
  {{- if eq $eventBusType "nats" }}
    {{- $eventBusName = default "codefresh-eventbus" .name }}
  {{- else if eq $eventBusType "jetstream" }}
    {{- $eventBusName = default "codefresh-eventbus-jetstream" .name }}
  {{- else }}
    {{- fail (printf "ERROR: EventBus type %s is inavlid, must be nats|jetstream" $eventBusType ) }}
  {{- end }}

{{- printf "%s" $eventBusName }}
{{- end }}
