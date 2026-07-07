<!-- AI-AGENT NOTE: leaf-directory CLAUDE.md, scoped to this directory. Root
CLAUDE.md has the whole-repo index. -->

# scripts/

Small, self-contained shell scripts supporting local development. None of
these run in CI (there is none configured yet — see the Constitution's
Development Workflow section); they're meant to be run manually.

## What's here

- `setup-helm-repos.sh` — registers the upstream Helm repos this repo's
  charts depend on (`helm repo add ...` + `helm repo update`). Run once
  per workstation, or whenever a new upstream repo is added.
- `bootstrap-cluster.sh` — idempotent: creates the local `kind` cluster (if
  it doesn't already exist) and installs Argo CD. Safe to re-run.
- `lint-all.sh` — discovers every chart in the repo (`chart/`,
  `platform-addons/`, `team-addons/`, and any `*/default-add-ons/*` with a
  `Chart.yaml`) and runs `helm dependency build && helm lint && helm
  template` on each, exiting non-zero on the first failure. This is the
  Constitution's Helm Lint Gate (Principle II), made runnable in one
  command.

## Read next

- `../docs/pattern/reproduction-guide.md` — where these scripts fit in the
  bootstrap sequence
