{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "argo-gateway.fullname" -}}
{{- print "argo-gateway" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "argo-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "argo-gateway.labels" -}}
helm.sh/chart: {{ include "argo-gateway.chart" . }}
{{ include "argo-gateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: argo-gateway
app.kubernetes.io/component: argo-gateway
codefresh.io/internal: "true"
codefresh.io/runtime-name: {{ .Values.global.runtime.name | quote }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "argo-gateway.selectorLabels" -}}
app.kubernetes.io/name: argo-gateway
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "argo-gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "argo-gateway.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
