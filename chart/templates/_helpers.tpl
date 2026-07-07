{{/*
chart.mergedValues
------------------
Deep-merges this chart's values in precedence order (lowest to highest):

  1. base   - the chart's already-loaded .Values (values.yaml)
  2. env    - optional overlay file "values-<environment>.yaml", where
              <environment> is .Values.environment
  3. cluster - optional overlay file "values-<clusterName>.yaml", where
              <clusterName> is .Values.clusterName (highest precedence)

Overlay files are not part of Helm's auto-loaded values.yaml, so they are
read explicitly via .Files.Get and parsed with fromYaml. A missing overlay
file (e.g. before it has been authored, or when environment/clusterName is
unset) is treated as an empty overlay rather than an error, so this helper
is safe to call standalone before values-{env}.yaml / values-{cluster}.yaml
exist.

The merge itself uses Sprig's mergeOverwrite, which merges its later
arguments on top of its first (destination) argument - i.e. cluster wins
over env, env wins over base - and mutates/returns the destination map. The
destination is deep-copied first so repeated calls (e.g. once per `apps`
entry in applications.yaml) never leak state into `.Values` or into each
other.

Usage:
  {{- $merged := include "chart.mergedValues" . | fromYaml }}
  {{- $merged.clusterName }}

Returns: a YAML document of the merged values map.
*/}}
{{- define "chart.mergedValues" -}}
{{- $base := deepCopy .Values -}}
{{- $environment := .Values.environment | default "" -}}
{{- $clusterName := .Values.clusterName | default "" -}}
{{- $envOverlay := dict -}}
{{- if $environment -}}
{{- $envFile := printf "values-%s.yaml" $environment -}}
{{- if .Files.Glob $envFile -}}
{{- $envOverlay = .Files.Get $envFile | fromYaml | default dict -}}
{{- end -}}
{{- end -}}
{{- $clusterOverlay := dict -}}
{{- if $clusterName -}}
{{- $clusterFile := printf "values-%s.yaml" $clusterName -}}
{{- if .Files.Glob $clusterFile -}}
{{- $clusterOverlay = .Files.Get $clusterFile | fromYaml | default dict -}}
{{- end -}}
{{- end -}}
{{- mergeOverwrite $base $envOverlay $clusterOverlay | toYaml -}}
{{- end -}}
