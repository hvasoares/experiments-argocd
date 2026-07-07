# Runbook: Bump a Pinned Upstream Chart Version

Every `default-add-ons/*` wrapper chart pins an explicit upstream chart
version in its `Chart.yaml` `dependencies[].version` — no floating ranges
(Constitution Principle IV). Use this runbook whenever that pin needs to move
to a newer upstream release (e.g. `bitnami/postgresql` `18.7.12` → a later
patch/minor).

## Prerequisites

- The upstream chart repo is already registered locally
  (`scripts/setup-helm-repos.sh`, or `helm repo add <name> <url>`).
- `helm repo update` has been run recently, so `helm search repo` reflects
  the latest published versions.

## Step 1: Update the version pin

1. Run `helm search repo <repo>/<chart> --versions` to find the exact new
   version string you want (copy it verbatim — do not guess or round).
2. Edit the wrapper chart's `Chart.yaml` (e.g.
   `platform-addons/default-add-ons/postgresql/Chart.yaml`) and set
   `dependencies[].version` to the new pin. Never use `*`, `~`, `^`, or
   `latest`.
3. Update the corresponding row in `docs/PREREQUISITES.md`'s "Pinned Chart
   Versions" table (Chart Version and App Version columns) so the doc stays
   the single source of truth for what's pinned. If the same upstream chart
   is pinned by more than one wrapper (e.g. `bitnami/postgresql` in both
   `platform-addons` and `team-addons`), update every wrapper that shares the
   pin, per data-model.md's Wrapper Chart Dependency contract.

## Step 2: Rebuild and verify locally

Run, from the wrapper chart's directory:

```bash
helm dependency build
helm lint
helm template .
```

All three MUST succeed (Constitution Principle II — Helm Lint Gate). Review
the `helm template` output for any values that no longer apply — a version
bump can rename or remove values keys, which `helm lint` alone will not
always catch. If the wrapper chart is referenced by a parent app-of-apps
chart (`platform-addons`/`team-addons`), re-run the same three commands one
layer up as well, since a broken leaf can still render at the parent level
if the leaf's own template errors are swallowed by defaults.

## Step 3: Re-sync via Argo CD

1. Commit the `Chart.yaml` and `docs/PREREQUISITES.md` changes and push (or
   otherwise make the change visible to Argo CD's configured Git source).
2. Trigger a sync for the affected Application(s):
   `argocd app sync <platform-addons|team-addons>`, or let Argo CD's
   auto-sync pick it up if enabled.
3. Confirm the Application(s) reach `Synced`/`Healthy`:
   `argocd app get <app-name>`. If the bump introduced a breaking values
   change missed in Step 2, the Application will go `Degraded` — roll the
   `Chart.yaml` version back to the previous pin and repeat from Step 1
   rather than debugging live against the cluster (Constitution Principle
   V — Local Verification Before Cluster Sync).
