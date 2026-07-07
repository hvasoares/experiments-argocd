# Implementation Plan: Argo CD App-of-Apps Experiment

**Branch**: `001-app-of-apps-experiment` | **Date**: 2026-07-07 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-app-of-apps-experiment/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Build a Helm/Argo CD chart hierarchy — one parent app-of-apps chart, two child
app-of-apps charts (`platform-addons`, `team-addons`) — that renders leaf Argo
CD `Applications` for ingress-nginx, a platform PostgreSQL instance, a team
PostgreSQL instance, and Outline. Cluster context and environment values flow
from the parent down through each layer via reusable Helm helpers. All charts
live in this one repository as sibling directories; validation is
`helm lint`/`helm template` first, then a local kind-based Kubernetes cluster
smoke test, with Argo CD sync as the final confirmation step (per the repo
constitution).

## Technical Context

**Language/Version**: Helm chart templates (Go template / Sprig), Helm 3.x CLI. No application source code is authored — workloads are pre-built upstream images (ingress-nginx, Bitnami PostgreSQL, Outline).

**Primary Dependencies**: Helm 3.x, Argo CD (targeting the existing 3.4.4 line per prior art), upstream Helm charts — `ingress-nginx/ingress-nginx`, `bitnami/postgresql`, and an Outline community chart (or a thin wrapper around the Outline image if no maintained chart fits) — each pinned to an explicit version resolved at implementation time via `helm search repo`.

**Storage**: PostgreSQL, via two independently-provisioned `bitnami/postgresql` releases (`postgresql-platform`, `postgresql-team`); no other persistent storage in scope.

**Testing**: `helm lint` + `helm dependency build` + `helm template` per chart (Constitution Principle II); local smoke apply against a `kind` cluster for anything touching runtime behavior (Constitution Principle V); `argocd app manifests`/`argocd app diff` as the pre-sync confirmation.

**Target Platform**: Local Docker-based Kubernetes (`kind`, since Docker is already available in this environment and no cluster currently exists) — no cloud/EKS provisioning in scope.

**Project Type**: Infrastructure-as-code / GitOps chart repository — single monorepo containing multiple sibling Helm charts (not a conventional src/tests application).

**Performance Goals**: Not applicable — internal playground, no throughput/latency targets. Success is measured by sync health and reachability (see spec Success Criteria).

**Constraints**: No source file over 200 lines (Constitution Principle III); every chart independently `helm lint`-able (Constitution Technology Stack & Constraints); wrapper charts pin explicit upstream versions, no floating ranges (Constitution Principle IV); no cloud IAM/IRSA — Postgres auth via Kubernetes Secrets only (spec Assumptions).

**Scale/Scope**: One local cluster, one parent chart, two child app-of-apps charts, four leaf Applications, two Postgres instances, one ingress controller, one team application (Outline).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. GitOps via Argo CD | All four leaf workloads and both child app-of-apps charts are deployed exclusively as Argo CD `Applications` sourced from this repo; the only manual step is the one-time root `Application` apply, documented in quickstart.md. | PASS |
| II. Helm Lint Gate | Every chart (parent, platform-addons, team-addons, and each `default-add-ons/*` wrapper) is validated with `helm dependency build && helm lint && helm template` before being considered complete (FR-009, SC-005). | PASS |
| III. 200-Line File Ceiling | Project Structure below splits each app-of-apps chart's leaf templates one-per-resource and keeps `_helpers.tpl` scoped by concern, so no template needs to grow past ~50-80 lines; enforced per-file, not just per-chart. | PASS |
| IV. App-of-Apps Modularity | Structure is exactly parent → platform-addons/team-addons → `default-add-ons/*` wrapper → pinned upstream chart, matching the constitution's required shape (FR-001, FR-003, FR-004, FR-010). | PASS |
| V. Local Verification Before Cluster Sync | quickstart.md's validation flow is `helm template` → `kind` cluster apply-and-observe → Argo CD sync, in that order, for every chart change. | PASS |

No violations — Complexity Tracking is not needed for this plan.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
bootstrap/
└── root-application.yaml        # one-time manual apply (Constitution Principle I)

chart/                            # parent app-of-apps chart
├── Chart.yaml
├── values.yaml
├── values-{env}.yaml             # per-environment overlay (deep-merged)
├── values-{cluster}.yaml         # per-cluster overlay (deep-merged, highest precedence)
└── templates/
    ├── _helpers.tpl              # child-values merge helper only
    └── applications.yaml         # one Application per `apps` entry

platform-addons/                  # child app-of-apps chart (platform-owned)
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl              # add-on-path / get-environment helpers only
│   └── addons/
│       ├── ingress-nginx.yaml    # leaf Application, gated by .Values.customAddons.platform.ingressNginx.enable
│       └── postgresql.yaml       # leaf Application, gated by .Values.customAddons.platform.postgresql.enable
└── default-add-ons/
    ├── ingress-nginx/
    │   ├── Chart.yaml            # dependency: ingress-nginx/ingress-nginx, pinned version
    │   └── values.yaml
    └── postgresql/
        ├── Chart.yaml            # dependency: bitnami/postgresql, pinned version
        └── values.yaml           # platform defaults (e.g. metrics.enabled: false)

team-addons/                      # child app-of-apps chart (team-owned), mirrors platform-addons shape
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl
│   └── addons/
│       ├── postgresql.yaml       # leaf Application → postgresql-team
│       └── outline.yaml          # leaf Application → outline, DATABASE_URL → postgresql-team Service
└── default-add-ons/
    ├── postgresql/
    │   ├── Chart.yaml            # same bitnami/postgresql version pin as platform
    │   └── values.yaml           # team overlay (e.g. metrics.enabled: true), distinct namespace/secret
    └── outline/
        ├── Chart.yaml            # dependency: Outline community chart, pinned version
        └── values.yaml           # Ingress host, DATABASE_URL template

docs/
└── runbooks/
    └── bump-chart-version.md     # 3-step version-bump runbook (spec Phase 10 item 47)
```

**Structure Decision**: Single monorepo, chart-per-directory layout (no
src/tests split — this is infrastructure-as-code, not an application). All
three chart tiers (`chart/`, `platform-addons/`, `team-addons/`) and their
`default-add-ons/*` wrapper charts live as siblings in this one repository,
per the spec's Assumptions (no multi-repo split). Each `templates/addons/`
file wraps exactly one leaf `Application`, and each `_helpers.tpl` is scoped
to one concern, keeping every file well under the 200-line ceiling. There is
no `tests/` directory: validation is `helm lint`/`helm template` per chart
plus the `kind`-cluster smoke flow captured in `quickstart.md`, run locally
per the constitution's Development Workflow (no CI configured yet).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
