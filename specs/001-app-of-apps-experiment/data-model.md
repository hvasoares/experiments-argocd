# Data Model: Argo CD App-of-Apps Experiment

This feature has no application data model in the traditional sense — the
"entities" are chart/values structures that flow through the Helm hierarchy.
This document captures their shape, fields, and relationships as they would
appear in `values.yaml` files, so implementation tasks have a single source
of truth for the values contract each layer expects from its caller.

## Cluster Context Values

Propagated from the parent chart into every child and leaf Application.

| Field | Type | Description |
|---|---|---|
| `clusterName` | string | Logical name of the target cluster (e.g. `kind-argocd-playground`). |
| `account` | string | Placeholder account identifier, kept for parity with the mirrored pattern; not used for cloud auth in this experiment. |
| `region` | string | Placeholder region identifier, same parity purpose as `account`. |
| `dns` | string | Base DNS suffix used to build per-app Ingress hostnames (e.g. `example.com` → `outline.<clusterName>.example.com`). |
| `environment` | string | Logical environment name (e.g. `local`), selects which `values-{env}.yaml` overlay applies. |

**Relationships**: Read by the parent chart's `chart.mergedValues` helper;
written into each child app-of-apps `Application`'s `spec.source.helm.valuesObject`
(see Leaf Application Values Contract below).

## Registered App (parent chart `apps` entry)

One entry per child app-of-apps chart, keyed under `.Values.apps`.

| Field | Type | Description |
|---|---|---|
| `name` | string (map key) | App identifier, becomes the Argo CD `Application` name (e.g. `platform-addons`). |
| `enabled` | bool | Whether this app renders at all. |
| `repoURL` | string | Git repo URL for the child chart's source (this repo's URL, since all charts are siblings — see spec Assumptions). |
| `path` | string | Path within the repo to the child chart (e.g. `platform-addons`). |
| `targetRevision` | string | Git ref to sync from (e.g. `HEAD` or a branch name). |
| `values` | map (optional) | App-specific value overrides merged on top of Cluster Context Values before being passed to the child. |

**Validation rules**: `enabled` defaults to `true` for the two apps registered
in this experiment (`platform-addons`, `team-addons`) — both must render by
default for the parent chart's own acceptance scenario (spec User Story 1:
"renders one Application per apps entry") and the quickstart flow to hold;
a *new* entry added later, for an app not yet ready to deploy, SHOULD instead
be added with `enabled: false` until turned on. `path` MUST
point at a directory that exists in this same repo, per the Assumptions'
single-repo constraint.

**Relationships**: One `Registered App` → one Argo CD `Application` CR → one
child app-of-apps chart render (User Story 1).

## Add-on Toggle (child chart `customAddons` entry)

One entry per leaf Application, keyed under
`.Values.customAddons.{platform|team}.{addonName}`.

| Field | Type | Description |
|---|---|---|
| `enable` | bool | Whether this leaf Application renders. |
| `namespace` | string | Target namespace for the leaf workload. |
| `chartPath` | string | Path to the wrapper chart under `default-add-ons/`. |
| `values` | map | Inline overrides passed as `spec.source.helm.values` on the leaf Application (e.g. `metrics.enabled`). |

**Validation rules**: `namespace` MUST differ between the platform and team
copies of the same addon type (`platform` vs `team`) to satisfy FR-005/FR-006
isolation requirements; `values` MUST NOT reference the sibling tier's
Service name (enforced by convention/review, not by schema).

**Relationships**: One `Add-on Toggle` → one leaf Argo CD `Application` CR →
one wrapper chart (`default-add-ons/*`) → one pinned upstream chart
dependency.

## Wrapper Chart Dependency

Declared in each `default-add-ons/*/Chart.yaml`.

| Field | Type | Description |
|---|---|---|
| `name` | string | Upstream chart name (e.g. `postgresql`). |
| `version` | string | Explicit pinned semver — no ranges (Constitution Principle IV). |
| `repository` | string | Upstream Helm repo URL (e.g. `https://charts.bitnami.com/bitnami`). |

**Relationships**: Platform and team `postgresql` wrapper charts both
reference the **same** `name`/`version`/`repository` (spec item: "team wrapper
pins same bitnami/postgresql chart version as platform"), differing only in
their own `values.yaml` overlay — not in the dependency pin itself.

## State / Lifecycle (Argo CD Application health)

Not a data entity but a status this model must expose for the spec's Success
Criteria (SC-001, SC-002): each rendered `Application` reaches one of Argo
CD's standard sync/health states (`Unknown` → `Progressing` → `Synced` /
`Healthy`, or `Degraded`/`Missing` on failure — e.g. a referenced Postgres
auth Secret not yet existing, per spec Edge Cases). No custom state machine is
introduced; this repo relies entirely on Argo CD's built-in status model.
