{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cluster-event-reporter.fullname" -}}
{{- print "cluster-event-reporter" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cluster-event-reporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cluster-event-reporter.labels" -}}
helm.sh/chart: {{ include "cluster-event-reporter.chart" . }}
{{ include "cluster-event-reporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: cluster-event-reporter
codefresh.io/internal: "true"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cluster-event-reporter.selectorLabels" -}}
app.kubernetes.io/name: cluster-event-reporter
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cluster-event-reporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cluster-event-reporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
