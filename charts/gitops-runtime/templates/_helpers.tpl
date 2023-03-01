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
{{- template "argo-cd.server.fullname" (dict "Values" (get .Values "argo-cd")) }}
{{- end }}

{{/*
Determine argocd servicename. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.appcontroller.serviceAccountName" -}}
{{/* For now use template from ArgoCD chart until better approach */}}
{{- template "argo-cd.controllerServiceAccountName" (dict "Values" (get .Values "argo-cd")) }}
{{- end }}

{{/*
Determine rollouts name
*/}}
{{- define "codefresh-gitops-runtime.argo-rollouts.name" -}}
{{/* For now use template from rollouts chart until better approach */}}
{{- template "argo-rollouts.fullname" (dict "Values" (get .Values "argo-rollouts")) }}
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
Determine argocd server url. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.server.url" -}}
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- $protocol := "https" }}
{{- $serverName := include "codefresh-gitops-runtime.argocd.server.servicename" . }}
{{- $port := include "codefresh-gitops-runtime.argocd.server.serviceport" . }}
{{- if (eq $port "80") }}
  {{- $protocol = "http" }}
{{- end }}
{{- printf "%s://%s:%s" $protocol $serverName $port }}
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
{{/* For now use template from Argo workflows chart until better approach */}}
{{- printf "https://%s:2746" (include "codefresh-gitops-runtime.argo-workflows.server.name" .) }}
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
    {{- if .Values.global.runtime.ingress.enabled }}
      {{- $supportedProtocols := list "http" "https" }}
      {{- if has .Values.global.runtime.ingress.protocol $supportedProtocols }}
        {{- printf "%s://%s" .Values.global.runtime.ingress.protocol  (index .Values.global.runtime.ingress.hosts 0)}}
      {{- else }}
          {{ fail (printf "ERROR: Unsupported protocol %s for ingress. Only http and https supported" .Values.global.runtime.ingress.protocol)}}
      {{- end }}
    {{- else }}
      {{- $accoundId := required "codefresh.accountId is required" .Values.global.codefresh.accountId }}
      {{- $runtimeName := required "runtime.name is required" .Values.global.runtime.name }}
      {{- $tunnelPrefix := printf "%s-%s" .Values.global.codefresh.accountId .Values.global.runtime.name }}
      {{- $tunnelHost := index (get .Values "tunnel-client") "tunnelServer" "subdomainHost"}}
      {{- printf "https://%s.%s" $tunnelPrefix $tunnelHost }}
    {{- end }}
{{- end }}

{{/*
Output comma separated list of installed runtime components
*/}}
{{- define "codefresh-gitops-runtime.component-list"}}
  {{- $argoCD := dict "name" "argocd" "version" (get .Subcharts "argo-cd").Chart.AppVersion }}
  {{- $argoEvents := dict "name" "argo-events" "version" (get .Subcharts "argo-events").Chart.AppVersion }}
  {{- $sealedSecrets := dict "name" "sealed-secrets" "version" (get .Subcharts "sealed-secrets").Chart.AppVersion }}
  {{- $internalRouter := dict "name" "internal-router" "version" .Chart.Version }}
  {{- $eventsReporter := dict "name" "events-reporter" "version" .Chart.Version }}
  {{- $appProxy := dict "name" "app-proxy" "version" (index (get .Values "app-proxy") "image" "tag") }}
  {{- $comptList := list $argoCD $argoEvents $appProxy $eventsReporter $sealedSecrets $internalRouter}}
  {{- if index (get .Values "argo-rollouts") "enabled" }}
    {{- $rolloutReporter := dict "name" "rollout-reporter" "version" .Chart.Version }}
    {{- $argoRollouts := dict "name" "argo-rollouts" "version" (get .Subcharts "argo-rollouts").Chart.AppVersion }}
    {{- $comptList = append $comptList $argoRollouts }}
    {{- $comptList = append $comptList $rolloutReporter }}
  {{- end }}
  {{- if index (get .Values "argo-workflows") "enabled" }}
    {{- $workflowReporter := dict "name" "workflow-reporter" "version" .Chart.Version }}
    {{- $argoWorkflows := dict "name" "argo-workflows" "version" (get .Subcharts "argo-workflows").Chart.AppVersion }}
    {{- $comptList = append $comptList $workflowReporter}}
    {{- $comptList = append $comptList $argoWorkflows }}
  {{- end }}
  {{- if not .Values.global.runtime.ingress.enabled }}
    {{- $tunnelClient := dict "name" "codefresh-tunnel-client" "version" (get .Subcharts "tunnel-client").Chart.AppVersion }}
    {{- $comptList = append $comptList $tunnelClient }}
  {{- end }}
{{- $comptList | toYaml }}
{{- end }}

# ------------------------------------------------------------------------------------------------------------
# Git integration
------------------------------------------------------------------------------------------------------------
{{- define "codefresh-gitops-runtime.git-integration.provider"}}
  {{- if .Values.global.codefresh.gitIntegration.provider.name }}
    {{- $supportedProviders := list "GITHUB" "GITLAB" "BITBUCKET" "BITBUCKET_CLOUD" }}
    {{- if has .Values.global.codefresh.gitIntegration.provider.name $supportedProviders }}
      {{- print .Values.global.codefresh.gitIntegration.provider.name }}
    {{- else }}
      {{ fail (printf "ERROR: Unsupported git provider %s. Currently supported: GITHUB,GITLAB,BITBUCKET,BITBUCKET_CLOUD" .Values.global.codefresh.gitIntegration.provider.name)}}
    {{- end }}
  {{- else }}
    {{ fail "Values.global.codefresh.gitIntegration.provider.name is required"}}
  {{- end }}
{{- end }}

{{- define "codefresh-gitops-runtime.git-integration.apiUrl"}}
  {{- if .Values.global.codefresh.gitIntegration.provider.apiUrl }}
    {{- print .Values.global.codefresh.gitIntegration.provider.apiUrl }}
  {{- else }}
    {{ fail "Values.global.codefresh.gitIntegration.provider.apiUrl is required"}}
  {{- end }}
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
