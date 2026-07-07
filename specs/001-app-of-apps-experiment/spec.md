# Feature Specification: Argo CD App-of-Apps Experiment

**Feature Branch**: `001-app-of-apps-experiment`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "@initial.prompt.md" — actionable to-do list to replicate the add-ons app-of-apps pattern (parent → platform/team add-ons → leaf Argo CD Application → Helm wrapper → upstream chart) in this fresh playground repo, using ingress-nginx, Bitnami PostgreSQL, and Outline as the exercise workloads.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Stand up the app-of-apps topology (Priority: P1)

A platform engineer working in this repo wants a single root Argo CD Application
that, once synced, brings up the entire chart hierarchy — a parent app-of-apps
chart that in turn deploys a "platform add-ons" child and a "team add-ons"
child — without any manual `kubectl apply` beyond the initial bootstrap. This
proves the core GitOps mechanic the whole playground exists to rehearse.

**Why this priority**: Nothing else in this experiment is testable until the
three-tier chart hierarchy (parent → platform/team → leaf) actually renders and
syncs. It's the foundation every other story depends on.

**Independent Test**: Run `helm template` on the parent chart with representative
values and confirm it emits two child `Application` manifests (`platform-addons`,
`team-addons-experiment`); then apply the root `Application` to a local cluster
and confirm Argo CD shows both children as synced.

**Acceptance Scenarios**:

1. **Given** the parent chart's `values.yaml` lists `platform-addons` and
   `team-addons-experiment` under `apps`, **When** the chart is rendered,
   **Then** one Argo CD `Application` CR is emitted per entry, each pointing at
   the correct child chart path.
2. **Given** the root `Application` has been applied to a cluster running Argo
   CD, **When** Argo CD completes its sync, **Then** both child app-of-apps
   Applications appear as `Synced`/`Healthy`.

---

### User Story 2 - Platform add-ons are deployed cluster-wide (Priority: P2)

A platform engineer wants the platform add-ons chart to deploy the shared
cluster edge (ingress-nginx) and a platform-owned PostgreSQL instance as
independently toggleable leaf Applications, each carrying platform-only
defaults (e.g. metrics disabled).

**Why this priority**: Team-owned workloads (User Story 3) depend on the
ingress layer existing, and this story proves the "shared infrastructure"
half of the platform/team split described in the target topology.

**Independent Test**: Render the platform add-ons chart alone with
`ingress-nginx.enable=true` and `postgresql.enable=true` and confirm exactly
two leaf `Application` manifests are produced, each in its documented
namespace, and that disabling either flag removes only that Application.

**Acceptance Scenarios**:

1. **Given** `customAddons.platform.ingressNginx.enable` is `true`, **When**
   the platform chart is rendered, **Then** an `ingress-nginx` leaf
   Application is emitted targeting the `ingress-nginx` namespace.
2. **Given** `customAddons.platform.postgresql.enable` is `true`, **When**
   the platform chart is rendered, **Then** a `postgresql-platform` leaf
   Application is emitted targeting the `platform` namespace with
   metrics disabled by default.
3. **Given** either enable flag is `false`, **When** the chart is rendered,
   **Then** the corresponding leaf Application is absent from the output.

---

### User Story 3 - Team app is deployed with its own isolated database (Priority: P3)

A team owner wants their own Postgres instance and their Outline application
deployed into a `team` namespace, fully isolated from the platform's Postgres
instance, with Outline reachable through the shared ingress and connected only
to the team's own database.

**Why this priority**: This is the "team self-service on shared platform"
scenario the whole exercise is meant to demonstrate, but it only makes sense
once the platform layer (User Story 2) and the app-of-apps mechanic (User
Story 1) already work.

**Independent Test**: Render the team add-ons chart alone and confirm it
emits `postgresql-team` and `outline` leaf Applications, with Outline's
database connection value pointing at the team Postgres Service name (not the
platform one); then, on a synced cluster, confirm the Outline UI loads via its
ingress hostname and that team Postgres shows the only connection.

**Acceptance Scenarios**:

1. **Given** the team chart is rendered, **When** inspecting the `outline`
   leaf Application's inline values, **Then** its database connection string
   references the `postgresql-team` Service, never `postgresql-platform`.
2. **Given** `postgresql-team` and `outline` are `Healthy`/`Synced` in Argo
   CD, **When** requesting the Outline ingress hostname, **Then** the Outline
   UI (or its setup screen) is returned.
3. **Given** the team chart is rendered, **When** compared against the
   platform Postgres values, **Then** the team Postgres carries a distinct
   overlay (e.g. `metrics.enabled: true`) not present on the platform default.

---

### Edge Cases

- What happens when the team add-ons chart is synced before the platform
  add-ons chart (e.g. ingress-nginx not yet installed)? Outline's Application
  should still deploy; only its external reachability via ingress is affected
  until the platform layer catches up.
- How does the system behave if a wrapper chart's pinned upstream version is
  bumped but the values contract changed upstream? `helm lint`/`helm template`
  MUST fail loudly rather than deploy a subtly broken release.
- What happens if a Postgres auth secret referenced by a leaf Application does
  not exist in the target namespace yet? The leaf Application should surface
  as `Degraded`/`Missing` in Argo CD rather than silently starting with empty
  credentials.
- How is platform/team Postgres isolation verified, not just assumed? At
  least one check MUST confirm the two instances are backed by distinct
  Services/PVCs and that Outline's connection never resolves to the platform
  Service.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repo MUST provide a parent Helm chart that renders one Argo
  CD `Application` per entry under an `apps` values key, each pointing at a
  child app-of-apps chart path.
- **FR-002**: The parent chart MUST merge shared cluster context (e.g.
  `clusterName`, `account`, `region`, `dns`) into each child Application's
  inline values via a single reusable helper, rather than duplicating that
  logic per child.
- **FR-003**: The repo MUST provide a platform add-ons chart that renders
  `ingress-nginx` and `postgresql-platform` as independently toggleable leaf
  Applications, each wrapping a pinned upstream chart under
  `default-add-ons/`.
- **FR-004**: The repo MUST provide a team add-ons chart that renders
  `postgresql-team` and `outline` as leaf Applications, structurally mirroring
  the platform chart's shape (same helper conventions, same `default-add-ons/`
  wrapper layout).
- **FR-005**: The team Postgres instance MUST be fully isolated from the
  platform Postgres instance — distinct namespace, distinct credentials,
  distinct Service — and Outline's database connection MUST reference only
  the team instance.
- **FR-006**: Every leaf Application MUST carry at least one namespace-scoped
  or environment-scoped value that differs between platform and team (e.g.
  a metrics toggle), demonstrating the "shared chart, per-tenant override"
  pattern.
- **FR-007**: Outline MUST be reachable through ingress-nginx via a
  per-cluster hostname once its leaf Application is healthy.
- **FR-008**: Value resolution MUST follow a documented, deterministic merge
  order (base → environment → cluster) implemented via one reusable helper
  rather than ad-hoc overrides scattered per chart.
- **FR-009**: Every chart and wrapper chart in the hierarchy MUST render
  successfully via `helm template` and pass `helm lint` before being
  considered complete (ties to the repo's Helm Lint Gate principle).
- **FR-010**: Each wrapper chart under `default-add-ons/` MUST pin an
  explicit upstream chart version rather than a floating/latest range.

### Key Entities

- **Parent App-of-Apps Chart**: Root chart; renders one child Argo CD
  Application per registered app; owns cluster-context propagation and the
  environment/cluster values merge order.
- **Platform Add-ons Chart**: Child app-of-apps chart owned by the platform;
  renders leaf Applications for shared infrastructure (`ingress-nginx`,
  `postgresql-platform`).
- **Team Add-ons Chart**: Child app-of-apps chart owned by a team; renders
  leaf Applications for team-owned workloads (`postgresql-team`, `outline`),
  structurally mirroring the platform chart.
- **Leaf Application**: A single Argo CD `Application` wrapping one upstream
  Helm chart dependency (ingress-nginx, Bitnami PostgreSQL, or Outline),
  carrying namespace, pinned version, and inline value overrides.
- **Cluster Context Values**: The set of values (`clusterName`, `account`,
  `region`, `dns`, environment name) that flow from the parent chart down
  through every child and leaf Application.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Syncing the root Application brings all four leaf workloads
  (ingress-nginx, postgresql-platform, postgresql-team, outline) to
  `Synced`/`Healthy` in Argo CD without any manual cluster edit after the
  initial bootstrap.
- **SC-002**: The Outline UI (or its setup screen) is reachable through the
  ingress hostname within 5 minutes of the `outline` leaf Application
  reporting `Healthy`.
- **SC-003**: 100% of validation runs confirm the team and platform
  PostgreSQL instances are backed by separate Services — zero cases of
  Outline resolving to the platform database.
- **SC-004**: A reviewer can trace a single cluster-context value (e.g.
  `clusterName`) from the parent chart's values down to a leaf Application's
  inline values by reading the chart source alone, with no file in that
  chain exceeding the repo's 200-line file limit.
- **SC-005**: Every chart in the hierarchy (parent, platform, team, and each
  `default-add-ons/*` wrapper) passes `helm lint` and `helm template` with
  zero errors.

## Assumptions

- All charts (parent, platform add-ons, team add-ons, and their wrapper
  charts) live in this single repository as sibling directories — there is
  no multi-repo split into separate `platform-addons` / `team-addons` git
  repositories for this experiment.
- The target runtime is a local Docker-based Kubernetes cluster (e.g. kind or
  minikube) reachable from this workstation; no cloud/EKS provisioning is in
  scope.
- Drift/sync strategy for this experiment defaults to manual value copying
  between platform and team charts; automated sync (GitHub PRs or Argo
  multi-source) is explicitly out of scope for the MVP and may be added as a
  later, separate feature.
- IRSA/cloud IAM is out of scope; Postgres credentials are handled via
  Kubernetes Secrets only, per the locked stack decision.
- Upstream chart versions (ingress-nginx, Bitnami PostgreSQL, Outline
  community chart) are pinned to the latest stable release available at
  scaffold time and recorded in each wrapper chart's `Chart.yaml`.
- Ingress reachability is validated via a `Host`-header request against the
  local cluster's ingress entrypoint (e.g. port-forward or local load
  balancer), not a public DNS record.
