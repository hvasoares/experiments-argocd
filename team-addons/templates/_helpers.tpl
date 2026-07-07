{{/*
add-on-path returns the repo-relative path to a default-add-on wrapper chart
for this tier, given just the add-on's directory name under
default-add-ons/. Repo-relative (not chart-relative) because Argo CD's
Application spec.source.path is resolved from the repo root (see
contracts/child-to-leaf-application.md § Producer).

Usage: {{ include "team-addons.add-on-path" (dict "root" $ "name" "postgresql") }}
*/}}
{{- define "team-addons.add-on-path" -}}
{{- printf "%s/default-add-ons/%s" .root.Chart.Name .name -}}
{{- end -}}

{{/*
get-environment returns the logical environment name propagated from the
parent chart's Cluster Context Values (see data-model.md § Cluster Context
Values), read only through the top-level `environment` key per
contracts/parent-to-child-values.md § Consumer requirement. Defaults to
"local" so this chart still lints/templates standalone without the parent
chart having rendered first.

Usage: {{ include "team-addons.get-environment" . }}
*/}}
{{- define "team-addons.get-environment" -}}
{{- default "local" .Values.environment -}}
{{- end -}}
