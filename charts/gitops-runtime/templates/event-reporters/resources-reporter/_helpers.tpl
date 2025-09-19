{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "resources-reporter.fullname" -}}
{{- print "resources-reporter" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "resources-reporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "resources-reporter.labels" -}}
helm.sh/chart: {{ include "resources-reporter.chart" . }}
{{ include "resources-reporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: resources-reporter
codefresh.io/internal: "true"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "resources-reporter.selectorLabels" -}}
app.kubernetes.io/name: resources-reporter
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "resources-reporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "resources-reporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
