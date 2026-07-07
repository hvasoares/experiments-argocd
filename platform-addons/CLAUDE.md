<!-- AI-AGENT NOTE: leaf-directory CLAUDE.md, scoped to this chart. Root
CLAUDE.md has the whole-repo index. -->

# platform-addons/

The **platform tier** app-of-apps chart: shared cluster-wide infrastructure,
owned by the platform team. Renders leaf Applications for `ingress-nginx`
and `postgresql-platform`.

## What's here

- `templates/_helpers.tpl` — `add-on-path`/`get-environment` helpers.
  `add-on-path` returns a **repo-root-relative** path
  (`platform-addons/default-add-ons/<name>`) — see the gotcha below.
- `templates/addons/{ingress-nginx,postgresql}.yaml` — leaf Application
  templates, each gated by `.Values.customAddons.platform.<addon>.enable`
- `default-add-ons/ingress-nginx/`, `default-add-ons/postgresql/` — wrapper
  charts, each pinning one upstream dependency (see
  `../docs/PREREQUISITES.md` for exact versions)
- `values.yaml` — the `customAddons.platform.*` toggle entries (namespace,
  chart path, inline values) each leaf template reads

## Important: this chart is reused by `team-addons`

`default-add-ons/postgresql` here is **not just platform's own database** —
`team-addons`' Postgres leaf Application reuses this exact chart directory
directly via Argo CD multi-source, rather than declaring its own copy. If
you change this chart's `Chart.yaml` (version pin) or `values.yaml`
defaults, you are changing team's Postgres too. See
`../docs/pattern/library-reuse-pattern.md` before editing
`default-add-ons/postgresql/` for platform-only reasons.

## Gotchas specific to this chart

- `add-on-path`'s repo-root-relative prefix (`platform-addons/...`) is easy
  to forget — see `../docs/pattern/pitfalls.md`, "Leaf Application path not
  repo-root-relative" (this is the exact bug that happened in this repo).

## Read next

- `../docs/pattern/library-reuse-pattern.md` — the reuse-as-a-library trick
- `../docs/pattern/architecture.md` — full chart hierarchy
