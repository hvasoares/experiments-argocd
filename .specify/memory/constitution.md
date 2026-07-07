<!--
Sync Impact Report
- Version change: [template, unratified] → 1.0.0 (initial ratification)
- Modified principles: none (template placeholders filled for the first time)
- Added principles:
  - I. GitOps via Argo CD
  - II. Helm Lint Gate (NON-NEGOTIABLE)
  - III. 200-Line File Ceiling
  - IV. App-of-Apps Modularity
  - V. Local Verification Before Cluster Sync
- Added sections: Technology Stack & Constraints, Development Workflow
- Removed sections: none
- Templates requiring updates:
  - .specify/templates/plan-template.md ✅ no change needed (Constitution Check gate reads this file dynamically)
  - .specify/templates/spec-template.md ✅ no change needed (no constitution-specific references)
  - .specify/templates/tasks-template.md ✅ no change needed (no constitution-specific references)
  - .specify/templates/checklist-template.md ✅ no change needed (no constitution-specific references)
- Follow-up TODOs: none — no placeholders deferred
-->

# ArgoCD Playground Constitution

## Core Principles

### I. GitOps via Argo CD
All workload and add-on state MUST be declared in Git and reconciled by Argo CD;
manual `kubectl apply`/`helm install` against the cluster is permitted only for
one-time bootstrap (installing Argo CD itself, creating the root Application) and
MUST be documented as such. Every deployable unit (platform add-on, team add-on,
leaf app) is represented as an Argo CD `Application`, sourced from a Helm chart in
this repo. Drift between the live cluster and Git is a bug, not a feature.

**Rationale**: this repo exists to exercise the app-of-apps GitOps pattern; letting
manual changes leak into the cluster defeats the point of the playground and hides
chart bugs that would otherwise surface in `helm template`/Argo diffs.

### II. Helm Lint Gate (NON-NEGOTIABLE)
Every chart and wrapper chart (parent, platform add-ons, team add-ons, and each
`default-add-ons/*` wrapper) MUST pass `helm lint` and `helm template` cleanly
before a change is committed or a PR is opened. Chart dependencies MUST be built
(`helm dependency build`) as part of that check, not skipped. A chart that fails
lint or fails to render is not "done" regardless of what it looks like in the
editor.

**Rationale**: with several nested charts (parent → platform/team → wrapper →
upstream dependency), a broken values contract at one layer silently breaks
everything downstream; linting at each layer is the cheapest way to catch that
before it reaches Argo CD.

### III. 200-Line File Ceiling
No source file — Helm templates, `_helpers.tpl`, `values.yaml`, scripts, or docs —
MAY exceed 200 lines. When a template or helper approaches the limit, split it: by
resource (one template per Kubernetes kind), by concern (helpers by responsibility,
not one giant `_helpers.tpl`), or by extracting a new wrapper/sub-chart. This
applies to generated/rendered output review too — if `helm template` output for a
single file is unreadable at a glance, the source template is doing too much.

**Rationale**: with many apps and charts in one repo, small files are what keep
the tree navigable and diffs reviewable; a single 500-line values file or
mega-template is where drift and copy-paste bugs hide.

### IV. App-of-Apps Modularity
The chart tree MUST follow the parent → platform-addons / team-addons → leaf
Application structure documented in this repo's planning notes: a parent chart
that renders child `Application` CRs, platform/team app-of-apps charts that render
leaf `Application` CRs, and leaf apps that wrap a pinned upstream chart (or values
override) under `default-add-ons/`. New apps are added by extending this pattern,
not by inventing a parallel one. Each wrapper chart pins an explicit upstream chart
version — no floating `*`/`latest` dependency ranges.

**Rationale**: the whole point of this playground is to reproduce and exercise
the app-of-apps pattern; charts that don't fit the shape stop being a useful
rehearsal for the real thing, and floating versions make "it broke" undebuggable.

### V. Local Verification Before Cluster Sync
Before a chart change is pushed for Argo CD to pick up, it MUST be smoke-tested
locally: `helm template` with representative values, and — for anything touching
running behavior (new resource, changed probe, changed env/DB wiring) — a local
Docker/Kubernetes cluster (e.g. kind/minikube) apply-and-observe pass. Argo CD
sync is the confirmation step, not the first test.

**Rationale**: this is a playground meant for fast iteration; catching a broken
manifest in `helm template` or a local cluster costs seconds, catching it via a
failed Argo CD sync costs a debug cycle against a shared/bootstrap cluster.

## Technology Stack & Constraints

This repo targets Docker + Kubernetes as the runtime, Argo CD as the GitOps
controller, and Helm as the sole packaging format for deployable units (no raw
Kustomize/manifests as a competing mechanism unless wrapped inside a chart).
Upstream dependencies used by leaf apps (e.g. ingress-nginx, Bitnami PostgreSQL,
Outline, or others added later) are pulled as versioned Helm chart dependencies,
never vendored/copied source. Multiple independent apps and charts are expected
to coexist in this repo (platform-owned vs. team-owned), and each MUST remain
independently `helm lint`-able and independently syncable in Argo CD.

## Development Workflow

Chart changes go through: edit → `helm dependency build` → `helm lint` →
`helm template` (review rendered output) → local cluster smoke test when runtime
behavior is affected → commit/PR → Argo CD sync. Since this repo currently has no
CI configured, these checks are run locally by whoever makes the change; adding
CI to automate the lint/template gate (Principle II) is welcome but not yet
required for a change to land. PRs that add or modify a chart MUST state which of
the above checks were run.

## Governance

This constitution supersedes ad-hoc practices for this repo. Amendments are made
by editing this file directly (single-maintainer playground — no formal approval
board), and MUST include a version bump and an updated Sync Impact Report comment
at the top of the file. Versioning follows semantic versioning: MAJOR for removing
or redefining a principle, MINOR for adding a principle or materially expanding
guidance, PATCH for wording/clarification fixes. Any plan or task generated via
Spec Kit MUST verify compliance with the principles above (Constitution Check
gate); deviations must be justified in that plan's Complexity Tracking section
rather than silently ignored.

**Version**: 1.0.0 | **Ratified**: 2026-07-07 | **Last Amended**: 2026-07-07
