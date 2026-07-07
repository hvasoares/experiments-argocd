{{/*
add-on-path
Resolve the on-disk (repo-relative) path to a default-add-ons/<name> wrapper
chart by convention, given only the add-on's short name.

Usage:
  {{ include "add-on-path" "postgresql" }}
  => default-add-ons/postgresql

Callers (templates/addons/*.yaml) should prefer the explicit
`customAddons.<tier>.<addon>.chartPath` value from values.yaml (see
data-model.md § Add-on Toggle) and fall back to this helper only when no
override is set, e.g.:
  {{ .Values.customAddons.platform.postgresql.chartPath | default (include "add-on-path" "postgresql") }}
*/}}
{{- define "add-on-path" -}}
default-add-ons/{{ . }}
{{- end -}}

{{/*
get-environment
Resolve the active environment name propagated from the parent chart's
Cluster Context Values (see data-model.md § Cluster Context Values),
defaulting to "local" when the caller (root context) has no `environment`
value set, so this chart still lints/templates standalone per the
parent-to-child-values contract.

Usage:
  {{ include "get-environment" . }}
*/}}
{{- define "get-environment" -}}
{{- .Values.environment | default "local" -}}
{{- end -}}
