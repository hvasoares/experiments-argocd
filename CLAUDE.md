<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan:
`specs/002-repo-documentation/plan.md`

Prior feature: `specs/001-app-of-apps-experiment/plan.md` (the Argo CD
app-of-apps chart hierarchy this documentation feature describes).
<!-- SPECKIT END -->

<!--
AI-AGENT NOTE (Cursor/Claude/etc.): start here, then descend into whichever
directory's own CLAUDE.md matches what you're working on. Each one is
scoped to that directory only — this file is the index, not a summary of
everything below it.
-->

## Project index

Read [`docs/pattern/README.md`](docs/pattern/README.md) first for what this
repo actually demonstrates (an Argo CD app-of-apps GitOps pattern) — it's
the orientation doc; this table is just a directory map.

| Directory | What it is | Its own CLAUDE.md |
|---|---|---|
| `bootstrap/` | One-time root Argo CD Application manifest | [`bootstrap/CLAUDE.md`](bootstrap/CLAUDE.md) |
| `chart/` | Parent app-of-apps chart | [`chart/CLAUDE.md`](chart/CLAUDE.md) |
| `platform-addons/` | Platform tier chart (ingress-nginx, platform Postgres) | [`platform-addons/CLAUDE.md`](platform-addons/CLAUDE.md) |
| `team-addons/` | Team tier chart (Outline, team Postgres reused from `platform-addons`) | [`team-addons/CLAUDE.md`](team-addons/CLAUDE.md) |
| `docs/` | Reader-facing documentation, including the pattern doc set | [`docs/CLAUDE.md`](docs/CLAUDE.md) |
| `scripts/` | Local dev scripts (repo setup, cluster bootstrap, lint-all) | [`scripts/CLAUDE.md`](scripts/CLAUDE.md) |

`specs/` is Spec Kit's own planning trail (specs, plans, tasks) for each
feature — not indexed above since it's process history, not a "project."
