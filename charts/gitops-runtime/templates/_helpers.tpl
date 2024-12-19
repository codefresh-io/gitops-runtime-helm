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
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- template "argo-cd.server.fullname" (dict "Values" $argoCDValues) }}
{{- end }}

{{/*
Determine argocd repo server service name. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.reposerver.servicename" -}}
{{/* For now use template from ArgoCD chart until better approach */}}
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- if $argoCDValues.enabled }}
  {{- template "argo-cd.repoServer.fullname" (dict "Values" $argoCDValues) }}
{{- else if $argoCDValues.byoRepoServerName }}
  {{- $argoCDValues.byoRepoServerName }}
{{- else }}
  {{- fail "Must supply byoRepoServerName if argo-cd.enabled is false" }}
{{- end }}
{{- end }}

{{/*
Determine argocd argocd repo server port
*/}}
{{- define "codefresh-gitops-runtime.argocd.reposerver.serviceport" -}}
{{/* For now use template from ArgoCD chart until better approach */}}
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- if $argoCDValues.enabled }}
  {{- index $argoCDValues "repoServer" "service" "port" }}
{{- else if $argoCDValues.byoRepoServerPort }}
  {{- $argoCDValues.byoRepoServerPort }}
{{- else }}
  {{- fail "Must supply byoRepoServerPort if argo-cd.enabled is false" }}
{{- end }}
{{- end }}

{{/*
Determine argocd servicename. Must be called with chart root context
NOT BEING USED
*/}}
{{- define "codefresh-gitops-runtime.argocd.appcontroller.serviceAccountName" -}}
{{/* For now use template from ArgoCD chart until better approach */}}
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- template "argo-cd.controllerServiceAccountName" (dict "Values" $argoCDValues) }}
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
{{- if $argoCDValues.enabled }}
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
{{- else if $argoCDValues.byoServerPort }}
  {{ $argoCDValues.byoServerPort }}
{{- else }}
  {{- fail "Must supply byoServerPort URL if argo-cd.enabled is false" }}
{{- end }}
{{- end }}

{{/*
Determine argocd server url. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.server.url" -}}
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- if $argoCDValues.enabled }}
  {{- $protocol := "https" }}
  {{- $port := include "codefresh-gitops-runtime.argocd.server.serviceport" . }}
  {{- if (eq $port "80") }}
    {{- $protocol = "http" }}
  {{- end }}
  {{- $url := include "codefresh-gitops-runtime.argocd.server.no-protocol-url" . }}
  {{- printf "%s://%s" $protocol $url }}
{{- else if $argoCDValues.byoServerUrl }}
  {{- printf "%s" $argoCDValues.byoServerUrl }}
{{- else }}
  {{- fail "Must supply byoServerUrl if argo-cd.enabled is false" }}
{{- end }}
{{- end }}

{{/*
Determine argocd server url witout the protocol. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argocd.server.no-protocol-url" -}}
{{- $argoCDValues := (get .Values "argo-cd") }}
{{- if $argoCDValues.enabled }}
  {{- $serverName := include "codefresh-gitops-runtime.argocd.server.servicename" . }}
  {{- $port := include "codefresh-gitops-runtime.argocd.server.serviceport" . }}
  {{- $path := (get $argoCDValues.configs.params "server.rootpath") }}
  {{- printf "%s:%s%s" $serverName $port $path }}
{{- else if $argoCDValues.byoServerUrl }}
  {{- $urlDict := (urlParse $argoCDValues.byoServerUrl) }}
  {{- $_ := set $urlDict "scheme" "" }}
  {{- replace "//" "" (urlJoin $urlDict) }}
{{- else }}
  {{- fail "Must supply byoServerUrl if argo-cd.enabled is false" }}
{{- end }}
{{- end }}

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
  {{- $comptList := list $argoEvents $appProxy $sealedSecrets $internalRouter}}
  {{- if index (get .Values "argo-cd") "enabled" }}
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
    {{- $gitopsOperator := dict "name" "gitops-operator" "version" (get .Subcharts "gitops-operator").Chart.AppVersion }}
    {{- $comptList = append $comptList $gitopsOperator }}
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
