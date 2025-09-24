{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "argo-api-gateway.fullname" -}}
{{- print "argo-api-gateway" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "argo-api-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "argo-api-gateway.labels" -}}
helm.sh/chart: {{ include "argo-api-gateway.chart" . }}
{{ include "argo-api-gateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: argo-api-gateway
codefresh.io/internal: "true"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "argo-api-gateway.selectorLabels" -}}
app.kubernetes.io/name: argo-api-gateway
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "argo-api-gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "argo-api-gateway.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
