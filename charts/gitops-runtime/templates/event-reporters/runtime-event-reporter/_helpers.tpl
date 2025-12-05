{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "runtime-event-reporter.fullname" -}}
{{- print "runtime-event-reporter" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "runtime-event-reporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "runtime-event-reporter.labels" -}}
helm.sh/chart: {{ include "runtime-event-reporter.chart" . }}
{{ include "runtime-event-reporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: runtime-event-reporter
app.kubernetes.io/component: runtime-event-reporter
codefresh.io/internal: "true"
codefresh.io/runtime-name: {{ .Values.global.runtime.name | quote }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "runtime-event-reporter.selectorLabels" -}}
app.kubernetes.io/name: runtime-event-reporter
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "runtime-event-reporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "runtime-event-reporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
