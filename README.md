# Argo CD App-of-Apps Experiment

A playground that rehearses the parent → platform/team add-ons → leaf
Application → Helm wrapper → upstream chart pattern with Argo CD. One root
Application, once synced, brings up the entire hierarchy below with no
manual `kubectl apply` beyond the initial bootstrap.

See [`specs/001-app-of-apps-experiment/spec.md`](specs/001-app-of-apps-experiment/spec.md)
for the full feature spec, and
[`specs/001-app-of-apps-experiment/plan.md`](specs/001-app-of-apps-experiment/plan.md)
for the implementation plan.

## Topology

```text
bootstrap/root-application.yaml   (one-time manual apply)
        │
        ▼
   chart/                          parent app-of-apps chart
        │
        ├── platform-addons/       child app-of-apps chart (platform-owned)
        │       │
        │       ├── ingress-nginx           leaf Application
        │       │     └── default-add-ons/ingress-nginx  (wraps ingress-nginx/ingress-nginx)
        │       │
        │       └── postgresql-platform     leaf Application
        │             └── default-add-ons/postgresql      (wraps bitnami/postgresql)
        │
        └── team-addons/           child app-of-apps chart (team-owned)
                │
                ├── postgresql-team         leaf Application
                │     └── REUSES platform-addons/default-add-ons/postgresql directly
                │           (Argo CD multi-source — see docs/pattern/library-reuse-pattern.md)
                │
                └── outline                 leaf Application
                      └── default-add-ons/outline           (wraps community-charts/outline)
```

Cluster context (`clusterName`, `account`, `region`, `dns`, environment) flows
from `chart/values.yaml` down through every child and leaf `Application` via
one reusable merge helper (base → environment → cluster), per FR-002/FR-008
of the spec.

## Stack

| Workload | Owner | Namespace | Upstream chart | Distinguishing override |
|---|---|---|---|---|
| `ingress-nginx` | Platform | `ingress-nginx` | `ingress-nginx/ingress-nginx` | Shared cluster edge; fronts Outline's ingress hostname |
| `postgresql-platform` | Platform | `platform` | `bitnami/postgresql` | `metrics.enabled: false` (default) |
| `postgresql-team` | Team | `team` | `bitnami/postgresql` (reused directly from `platform-addons`, no separate wrapper — see [`docs/pattern/library-reuse-pattern.md`](docs/pattern/library-reuse-pattern.md)) | `metrics.enabled: true`; fully isolated Service/PVC/credentials from `postgresql-platform` |
| `outline` | Team | `team` | `community-charts/outline` | `DATABASE_URL` resolves only to the `postgresql-team` Service, never `postgresql-platform`; reachable through `ingress-nginx` via a per-cluster hostname |

Exact upstream chart version pins are recorded in
[`docs/PREREQUISITES.md`](docs/PREREQUISITES.md); every wrapper chart under
`default-add-ons/` pins an explicit version, never a floating range
(FR-010).

## Repository layout

```text
bootstrap/          one-time root Application manifest
chart/               parent app-of-apps chart
platform-addons/    platform child app-of-apps chart + default-add-ons wrappers
team-addons/         team child app-of-apps chart + default-add-ons wrappers
docs/                prerequisites, runbooks, and the pattern doc set (docs/pattern/)
scripts/             helm repo setup, cluster bootstrap, lint-all
specs/               spec, plan, data model, contracts, tasks for this feature
```

## Validation

Every chart in the hierarchy is independently `helm lint`-able and must pass,
per chart, before being considered complete:

```bash
helm dependency build <chart-dir> && helm lint <chart-dir> && helm template <chart-dir>
```

See [`specs/001-app-of-apps-experiment/quickstart.md`](specs/001-app-of-apps-experiment/quickstart.md)
for the full local `helm template` → `kind` smoke test → Argo CD sync
validation flow, and [`docs/runbooks/bump-chart-version.md`](docs/runbooks/bump-chart-version.md)
for how to bump a pinned upstream version safely.

## Pattern documentation

Want to reproduce this pattern in a new project, or assess whether it
applies to an existing one? Start at
[`docs/pattern/README.md`](docs/pattern/README.md) — it covers the
architecture, the "platform as a library" reuse trick, a step-by-step
reproduction guide, every real pitfall hit building this, and an
applicability assessment guide for a different project.
