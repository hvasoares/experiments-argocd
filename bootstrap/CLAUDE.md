<!-- AI-AGENT NOTE: this is a leaf-directory CLAUDE.md — scoped to this one
directory. Root CLAUDE.md has the whole-repo index; read that first if
you haven't. -->

# bootstrap/

The one-time, manually-applied entry point into the whole Argo CD
app-of-apps tree. Everything else in this repo is reconciled by Argo CD
itself; this directory is the sole exception — see Constitution Principle I
(GitOps via Argo CD) in `.specify/memory/constitution.md`.

## What's here

- `root-application.yaml` — a single Argo CD `Application` pointing at
  `chart/` (the parent app-of-apps chart). Applying this once
  (`kubectl apply -f bootstrap/root-application.yaml`) is what bootstraps
  everything else: it syncs `chart/`, which renders `platform-addons` and
  `team-addons` as child Applications, which in turn render every leaf
  workload.

## When you'd touch this

- Standing up a fresh cluster (see
  `../docs/pattern/reproduction-guide.md` step 9).
- Changing the parent chart's path/repo/target revision, or the sample
  cluster-context values (`clusterName`, `dns`, `environment`) passed in.

## Read next

- `../docs/pattern/reproduction-guide.md` — full bootstrap sequence
- `../chart/CLAUDE.md` — what this file points at
