#!/bin/bash
OUTPUTFILE=$1
# This template prints all values and also sets tags for all images with non-empty repository value, where the tag is empty and should be derived from the appVersion of the subchart.
ALL_VALUES_TEMPLATE=$(cat <<END
{{- define "recurse-set-image-tags"}}
  {{- \$map := .Values }}
  {{- \$root := .root }}
  {{- \$rootKey := .rootKey}}
  {{- range \$key, \$val := \$map -}}
    {{- if eq \$key "image" }}
      {{/* If tag is not provided, check for subchart appVersion*/}}
        {{ if kindOf \$val | eq "map" }}
          {{- if hasKey \$val "tag" }}
            {{- if contains "{{" \$val.tag }}
              {{- \$suspectedSubChart := \$rootKey }}
                {{- if hasKey \$root.Subcharts \$suspectedSubChart }}
                  {{ \$subchart := get \$root.Subcharts \$suspectedSubChart }}
                  {{- \$_ := set \$val "tag"  (tpl \$val.tag \$subchart) }}
                {{- else }}
                  {{- \$_ := set \$val "tag"  (tpl \$val.tag \$root) }}
                {{- end }}
            {{- end}}
            {{/* If tag has no value*/}}
            {{- if and (not \$val.tag) \$val.repository}}
              {{- \$suspectedSubChart := \$rootKey }}
              {{- if hasKey \$root.Subcharts \$suspectedSubChart }}
                {{ \$subchart := get \$root.Subcharts \$suspectedSubChart }}
                {{- \$_ := set \$val "tag"  \$subchart.Chart.AppVersion }}
              {{- else if eq \$rootKey "installer" }}
                {{- \$_ := set \$val "tag"  \$root.Chart.Version }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
    {{- else if kindOf \$val | eq "map" }}
{{- include "recurse-set-image-tags" (dict "rootKey" \$rootKey "root" \$root "Values" \$val) }}
    {{- end }}
  {{- end }}
{{- end }}

{{- if .Values.getImages }}
{{- \$mergedImagesDict := dict }}
{{- /* Iterate over all top level components (argocd, rollouts workflows, etc)*/}}
  {{- range \$key, \$val := .Values -}}
    {{- if kindOf \$val | eq "map" }}
      {{- /* Recursively get all paths containing image value */}}
      {{- \$imagesValsDict := include "recurse-set-image-tags" (dict "rootKey" \$key "root" \$ "Values" \$val) | fromYaml }}
    {{- end }}
  {{- end }}
{{ .Values | toYaml }}
{{- end }}
END
)

echo -e "$ALL_VALUES_TEMPLATE" > $CHARTDIR/templates/all-values.yaml
helm template --values $VALUESFILE --set getImages=true --show-only templates/all-values.yaml $CHARTDIR > $OUTPUTFILE
rm $CHARTDIR/templates/all-values.yaml
