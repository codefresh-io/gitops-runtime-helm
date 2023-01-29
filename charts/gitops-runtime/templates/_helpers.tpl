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
  {{- $protocol := "http" }}
{{- end }}
{{- printf "%s://%s:%s" $protocol $serverName $port }}
{{- end}}

{{/*
Determine argo workflows server url. Must be called with chart root context
*/}}
{{- define "codefresh-gitops-runtime.argo-workflows.server.url" -}}
{{/* For now use template from Argo workflows chart until better approach */}}
{{- printf "https://%s:2746" (include "argo-workflows.server.fullname" (dict "Values" (get .Values "argo-workflows"))) }}
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
      {{- print (index .Values.global.runtime.ingress.hosts 0)}}
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
  {{- $comptList := list "argocd" "argo-events" "app-proxy" "events-reporter" "sealed-secrets" "internal-router"}}
  {{- if index (get .Values "argo-rollouts") "enabled" }}
    {{- $comptList = append $comptList "argo-rollouts" }}
    {{- $comptList = append $comptList "rollout-reporter" }}
  {{- end }}
  {{- if index (get .Values "argo-workflows") "enabled" }}
    {{- $comptList = append $comptList "argo-wokflows"}}
    {{- $comptList = append $comptList "workflow-reporter" }}
  {{- end }}
  {{- if not .Values.global.runtime.ingress.enabled }}
  {{- $comptList = append $comptList "tunnel-client" }}
  {{- end }}
  {{- print (join "," $comptList) }}
{{- end }}