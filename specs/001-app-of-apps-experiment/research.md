# Research: Argo CD App-of-Apps Experiment

All items below were "NEEDS CLARIFICATION"-free in the spec (every open
question had a documented default under spec.md's Assumptions), so this
phase focuses on validating those defaults against the actual local
environment and recording implementation-time decisions that were
deliberately left open rather than hardcoded.

## Local cluster tooling

- **Decision**: Use `kind` (Kubernetes-in-Docker) for the local target
  cluster.
- **Rationale**: This workstation has Docker 29.5.3 available but no `helm`,
  `kind`, or `minikube` installed, and no existing kubeconfig context
  (`kubectl config get-contexts` returns empty). `kind` is the lightest-weight
  option that runs entirely on the already-present Docker daemon, is
  scriptable (`kind create cluster --config ...`), and is the de facto
  standard for Argo CD app-of-apps rehearsals. It matches the constitution's
  "local Docker/Kubernetes cluster (e.g. kind/minikube)" wording.
- **Alternatives considered**: `minikube` (heavier VM/driver setup, no
  advantage here since Docker driver would just reimplement what `kind`
  already does natively); Docker Desktop's built-in Kubernetes (not confirmed
  present/enabled on this machine, less scriptable for repeatable teardown).
- **Prerequisite implied for tasks**: `helm` and `kind` CLIs must be installed
  before any chart can be linted/tested — this becomes a Phase 2 setup task,
  not part of chart authoring itself.

## Upstream chart version pins

- **Decision**: Do not hardcode specific upstream chart versions (ingress-nginx,
  bitnami/postgresql, Outline community chart) in this plan. Resolve and pin
  the latest stable version of each via `helm repo add` + `helm search repo
  <chart> --versions` at the time each wrapper chart is scaffolded
  (implementation/task time), and record the chosen version directly in that
  wrapper's `Chart.yaml` `dependencies[].version`.
- **Rationale**: Chart registries move fast; a version pinned during planning
  would likely already be stale by implementation time, and Constitution
  Principle IV requires an explicit (not floating) pin regardless of which
  version is chosen — the "explicit" requirement doesn't require choosing it
  this far in advance.
- **Alternatives considered**: Pinning versions now from training-data
  knowledge — rejected because it risks pinning a version that no longer
  exists in the upstream repo index, which would fail `helm dependency build`
  immediately.

## Outline chart source

- **Decision**: Use a community-maintained Outline Helm chart if one exists
  and is actively maintained at implementation time (e.g. from a chart
  repository indexed by Artifact Hub); otherwise author a minimal wrapper
  chart in this repo (`team-addons/default-add-ons/outline/`) that templates
  a Deployment/Service/Ingress directly around the official Outline container
  image, since Outline itself does not ship an official Helm chart.
- **Rationale**: Matches the spec input's own hedge ("Community / wrapper Helm
  chart with Postgres URL") and keeps Constitution Principle IV's "leaf apps
  wrap a pinned upstream chart (or values override)" satisfied either way.
- **Alternatives considered**: Vendoring/copying an existing chart's templates
  into this repo — rejected, conflicts with the constitution's "never
  vendored/copied source" rule for upstream dependencies.

## Drift/sync strategy for MVP

- **Decision**: Manual value copying between `platform-addons` and
  `team-addons` for shared conventions (e.g. `_helpers.tpl` patterns, Postgres
  wrapper `values.yaml` shape). No automated sync pipeline (GitHub PR sync or
  Argo `spec.sources` multi-source) is built in this feature.
- **Rationale**: Spec Assumptions already default to this; the source
  planning notes explicitly mark both automation options (Phase 8 multi-source,
  Phase 9 sync pipeline) as optional, later work.
- **Alternatives considered**: Building Argo multi-source support now —
  deferred; would add scope without being required to prove the core
  app-of-apps mechanic (User Stories 1-3).

## Value merge order implementation

- **Decision**: Implement the `values.yaml` → `values-{env}.yaml` →
  `values-{cluster}.yaml` deep-merge as a single named template in the parent
  chart's `_helpers.tpl` (e.g. `chart.mergedValues`), called once per child
  entry when rendering `applications.yaml`, using Helm's built-in `mergeOverwrite`
  (Sprig) rather than a custom recursive merge function.
- **Rationale**: `mergeOverwrite`/`merge` are already part of Helm's bundled
  Sprig function set — no external library or subchart needed — and keep the
  helper well under the 200-line ceiling.
- **Alternatives considered**: A custom recursive-merge named template —
  rejected as unnecessary complexity given Sprig already provides this.
