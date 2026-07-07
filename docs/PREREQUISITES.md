# Prerequisites

Local CLI tooling required to develop, lint, and smoke-test the charts in
this repository. Verified on this machine on 2026-07-07.

| Tool | Purpose | Resolved Version |
|---|---|---|
| `helm` | Chart linting, templating, dependency management | v4.2.2+gb05881c |
| `kind` | Local Docker-based Kubernetes cluster for smoke testing | v0.32.0 (go1.26.3 darwin/arm64) |
| `kubectl` | Cluster interaction, applying manifests | v1.34.1 (Kustomize v5.7.1) |
| `argocd` | Argo CD CLI (`app manifests`/`app diff`) targeting the 3.4.4 line | v3.4.4+443415b.dirty |

## Installation

`kubectl` was already present on this machine and was not reinstalled.
`helm`, `kind`, and `argocd` were installed via Homebrew:

```bash
brew install helm kind argocd
```

## Verification commands

```bash
helm version --short
kind version
kubectl version --client
argocd version --client
```

## Pinned Chart Versions

Resolved via `helm search repo <chart> --versions` on 2026-07-07, after
`scripts/setup-helm-repos.sh` registered the `ingress-nginx` and `bitnami`
repos (T006). Each `default-add-ons/*` wrapper chart's `Chart.yaml` MUST pin
the exact `Chart Version` below in `dependencies[].version` — no floating
ranges (Constitution Principle IV).

| Wrapper chart | Upstream chart | Repository | Chart Version (pin) | App Version |
|---|---|---|---|---|
| `platform-addons/default-add-ons/ingress-nginx` | `ingress-nginx/ingress-nginx` | `https://kubernetes.github.io/ingress-nginx` | `4.15.1` | `1.15.1` |
| `platform-addons/default-add-ons/postgresql` | `bitnami/postgresql` | `https://charts.bitnami.com/bitnami` | `18.7.12` | `18.4.0` |
| `team-addons/default-add-ons/postgresql` | `bitnami/postgresql` | `https://charts.bitnami.com/bitnami` | `18.7.12` | `18.4.0` (same pin as platform, per data-model.md § Wrapper Chart Dependency) |
| `team-addons/default-add-ons/outline` | `community-charts/outline` | `https://community-charts.github.io/helm-charts` | `0.9.0` | `1.8.1` |

### Outline chart resolution

A maintained community Helm chart for Outline exists and was selected instead
of a hand-authored wrapper (research.md's fallback is therefore **not**
needed): `community-charts/outline`, published by the `community-charts`
GitHub org (`https://community-charts.github.io/helm-charts`). Verified
actively maintained — its `0.9.0` release (checked via `helm show chart
community-charts/outline`) tracks the current upstream `outlinewiki/outline:1.8.1`
image and its own `Chart.yaml` annotations show recent dependency bumps
(`bitnami/postgresql` 18.7.0 → 18.7.2, `bitnami/redis` 25.5.3 → 27.0.4).

Other Outline charts found via `helm search hub outline` were considered and
rejected: `outline/outline` (0.0.9) and `schmitzis/outline` (0.0.8) are
pre-1.0 with app version `0.69.x`, well behind current Outline; `kubitodev/outline`
and `cfi2017/getoutline` are single-maintainer charts with less evidence of
active upkeep than `community-charts`, which maintains a broad, regularly
updated catalog.

`team-addons/default-add-ons/outline/Chart.yaml` MUST declare:

```yaml
dependencies:
  - name: outline
    version: "0.9.0"
    repository: "https://community-charts.github.io/helm-charts"
```

The `community-charts` repo must be registered locally before this
dependency can be built — add `helm repo add community-charts
https://community-charts.github.io/helm-charts` to
`scripts/setup-helm-repos.sh` when that file is next touched (out of scope
for this task, which only records the version pin).
