{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "runtime-reporter.fullname" -}}
{{- print "runtime-reporter" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "runtime-reporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "runtime-reporter.labels" -}}
helm.sh/chart: {{ include "runtime-reporter.chart" . }}
{{ include "runtime-reporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: runtime-reporter
codefresh.io/internal: "true"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "runtime-reporter.selectorLabels" -}}
app.kubernetes.io/name: runtime-reporter
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "runtime-reporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "runtime-reporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
