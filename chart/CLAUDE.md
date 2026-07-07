<!-- AI-AGENT NOTE: leaf-directory CLAUDE.md, scoped to this chart. Root
CLAUDE.md has the whole-repo index. -->

# chart/

The **parent app-of-apps chart**. Its only job is rendering one Argo CD
`Application` per tier — it deploys no workloads directly.

## What's here

- `Chart.yaml`, `values.yaml` — chart metadata and the `apps:` registry
  (one entry per tier: `platform-addons`, `team-addons`)
- `values-local.yaml`, `values-kind-argocd-playground.yaml` — env/cluster
  value overlays, deep-merged by the helper below
- `templates/_helpers.tpl` — `chart.mergedValues`: the named template that
  deep-merges `values.yaml` → `values-{env}.yaml` → `values-{cluster}.yaml`
  (Sprig `mergeOverwrite`)
- `templates/applications.yaml` — loops `.Values.apps`, renders one child
  `Application` per entry using `chart.mergedValues`'s output

## Gotchas specific to this chart

- Every tier's `repoURL` in `values.yaml` must point at a real, reachable
  git remote once you sync against an actual cluster — see
  `../docs/pattern/pitfalls.md`, "Placeholder repoURL not reachable."

## Read next

- `../docs/pattern/architecture.md` — the "Value flow" section explains
  exactly what `chart.mergedValues` needs to produce
- `../platform-addons/CLAUDE.md`, `../team-addons/CLAUDE.md` — what this
  chart's `apps` entries point at
