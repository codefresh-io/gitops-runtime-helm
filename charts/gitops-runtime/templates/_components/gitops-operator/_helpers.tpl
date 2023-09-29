{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gitops-operator.fullname" -}}
{{- print "gitops-operator" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gitops-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gitops-operator.labels" -}}
helm.sh/chart: {{ include "gitops-operator.chart" . }}
{{ include "gitops-operator.selectorLabels" . }}
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
{{- define "gitops-operator.selectorLabels" -}}
app: gitops-operator
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "gitops-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "gitops-operator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}