<!-- AI-AGENT NOTE: leaf-directory CLAUDE.md, scoped to this chart. Root
CLAUDE.md has the whole-repo index. -->

# team-addons/

The **team tier** app-of-apps chart: a team-owned workload (Outline) and
its own isolated PostgreSQL instance.

## What's here

- `templates/_helpers.tpl` — `team-addons.add-on-path`/`get-environment`,
  mirroring `platform-addons`' helpers
- `templates/addons/outline.yaml` — leaf Application for Outline, wrapping
  `default-add-ons/outline` normally
- `templates/addons/postgresql.yaml` — leaf Application for team's
  Postgres, but **not** a normal wrapper — see below
- `default-add-ons/outline/` — the only wrapper chart this tier owns
  directly (pins a community Outline chart)
- `overlays/postgresql/values.yaml` — the ONE value team's Postgres
  overrides on top of `platform-addons`' chart (`metrics.enabled: true`)
  — nothing else belongs in this file, see
  `../docs/pattern/library-reuse-pattern.md`
- `values.yaml` — `customAddons.team.*` toggles; note
  `customAddons.team.postgresql.values` must nest under `postgresql:` (see
  gotcha below)

## Important: this tier's Postgres is not its own chart

`postgresql-team` has no `default-add-ons/postgresql` directory — it reuses
`platform-addons/default-add-ons/postgresql` directly via Argo CD
multi-source. If you're looking for "team's Postgres chart," it doesn't
exist as a separate thing; look in `platform-addons/` instead, and in this
directory's `overlays/postgresql/values.yaml` + `values.yaml`'s
`customAddons.team.postgresql.values` for what team changes on top.

## Gotchas specific to this chart

- `customAddons.team.postgresql.values` MUST nest under `postgresql:` —
  see `../docs/pattern/pitfalls.md`, "Inline override values not nested
  under the subchart name" (this exact mistake happened building this
  repo and cost real debugging time).
- `default-add-ons/outline/values.yaml`'s `outline.url` must match however
  you're actually accessing it (scheme + host, no port) — see
  `../docs/pattern/pitfalls.md`, "Canonical app URL must match."

## Read next

- `../docs/pattern/library-reuse-pattern.md` — full walkthrough of the
  Postgres reuse trick
- `../platform-addons/CLAUDE.md` — the chart this tier's Postgres reuses
