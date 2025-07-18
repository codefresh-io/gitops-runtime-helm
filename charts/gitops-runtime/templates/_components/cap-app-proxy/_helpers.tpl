{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cap-app-proxy.fullname" -}}
{{- print "cap-app-proxy" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cap-app-proxy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cap-app-proxy.labels" -}}
helm.sh/chart: {{ include "cap-app-proxy.chart" . }}
{{ include "cap-app-proxy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: app-proxy
codefresh.io/internal: "true"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cap-app-proxy.selectorLabels" -}}
app.kubernetes.io/name: cap-app-proxy
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cap-app-proxy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cap-app-proxy.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
