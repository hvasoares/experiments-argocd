<!--
AI-AGENT NOTE (Cursor/Claude/etc.): This file is written as instructions
for building the pattern in a NEW, EMPTY repo — not a description of what
already exists here. If a user says "set this pattern up in my project,"
follow these steps in order rather than trying to copy this repo's files
verbatim (paths like <org>/<repo> below are placeholders you must fill in
for the target project).
-->

# Reproduction guide: building this pattern from scratch

Read [`architecture.md`](./architecture.md) and
[`library-reuse-pattern.md`](./library-reuse-pattern.md) first — this file
assumes you already know the target shape.

## 0. Prerequisites

- `helm`, `kind` (or another local Kubernetes), `kubectl`, `argocd` CLI
- A git remote Argo CD's repo-server can actually reach (a `file://` local
  path does **not** work once Argo CD runs in-cluster — see
  [`pitfalls.md`](./pitfalls.md), "Placeholder repoURL not reachable")

## 1. Register upstream Helm repos

```bash
helm repo add <upstream-name> <upstream-url>   # once per upstream chart you'll wrap
helm repo update
```

## 2. Scaffold the parent chart

Create `chart/Chart.yaml` (apiVersion v2, no dependencies) and
`chart/values.yaml` with a top-level `apps:` map (one entry per tier you'll
add, each with `enabled`, `repoURL`, `path`, `targetRevision`).

## 3. Implement the parent's merge helper

In `chart/templates/_helpers.tpl`, add a named template that deep-merges
`values.yaml` → `values-{env}.yaml` → `values-{cluster}.yaml` via Sprig
`mergeOverwrite` (see architecture.md's "Value flow" section for exactly
what this needs to produce).

## 4. Implement the parent's rendering template

`chart/templates/applications.yaml`: loop over `.Values.apps`, render one
Argo CD `Application` per entry, `spec.source.helm.valuesObject` built by
the helper from step 3.

## 5. Scaffold each tier chart

For each tier (e.g. `platform-addons`, `team-addons`): `Chart.yaml`,
`values.yaml` with a `customAddons.<tier>: {}` placeholder, and
`templates/_helpers.tpl` with an `add-on-path` helper that returns
`<tier-dir>/default-add-ons/<name>` — **repo-root-relative, not
chart-relative** (see pitfalls.md, "Leaf Application path not
repo-root-relative" — this is the single most common mistake reproducing
this pattern).

## 6. Add wrapper charts and leaf Application templates

For each addon a tier owns directly (not reused from another tier): create
`<tier>/default-add-ons/<addon>/Chart.yaml` (pinned upstream dependency,
see architecture.md) and `values.yaml`, then
`<tier>/templates/addons/<addon>.yaml` rendering a leaf Application gated
by `.Values.customAddons.<tier>.<addon>.enable`, with
`syncOptions: [CreateNamespace=true]` set (see pitfalls.md — every leaf
Application needs this or the first sync fails).

## 7. Apply the "reuse as a library" pattern where it fits

If two tiers need the same upstream chart at the same version differing in
a small value set: skip step 6 for the second tier and instead follow
[`library-reuse-pattern.md`](./library-reuse-pattern.md)'s `spec.sources`
shape exactly.

## 8. Bootstrap a local cluster and Argo CD

```bash
kind create cluster --name <name>
kubectl create namespace argocd
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/<version>/manifests/install.yaml
kubectl -n argocd wait --for=condition=available deploy/argocd-server --timeout=180s
```

## 9. Push and wire the root Application

Push your repo to a real, reachable git remote. Create
`bootstrap/root-application.yaml` pointing `spec.source.repoURL`/`path` at
your parent chart (step 2-4), with sample `valuesObject` matching whatever
your `chart.mergedValues` helper expects. Apply it:

```bash
kubectl apply -f bootstrap/root-application.yaml
```

## 10. Sync and verify

Sync the root Application, then each tier, then each leaf, checking
`Synced`/`Healthy` at every level before moving to the next (don't sync
everything at once the first time — it's much easier to isolate which
layer is broken if you go one level at a time). Expect to hit at least one
of the pitfalls in [`pitfalls.md`](./pitfalls.md) the first time through —
they're not hypothetical, every one of them happened building this repo.

<!-- AI-AGENT NOTE: step 10's advice ("one level at a time") is not
optional politeness — debugging a fully-multi-source, fully-tiered sync
failure from scratch is much harder than debugging one layer. If you're
scripting this reproduction, sync root -> wait -> sync tiers -> wait ->
sync leaves, don't fire all syncs concurrently on the first attempt. -->
