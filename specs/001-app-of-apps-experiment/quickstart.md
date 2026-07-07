# Quickstart: Validate the Argo CD App-of-Apps Experiment

Follows Constitution Principle V (local verification before cluster sync):
`helm template` first, then a local `kind` cluster smoke test, then Argo CD
sync as the final confirmation. Run every step from the repo root.

## Prerequisites

- Docker (already available on this workstation)
- `helm` 3.x, `kind`, `kubectl`, `argocd` CLI — install if missing:
  ```bash
  brew install helm kind argocd   # or your platform's equivalent
  ```
- Upstream Helm repos registered:
  ```bash
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  ```

## 1. Lint and render every chart (no cluster required)

Run for each of `chart/`, `platform-addons/`, `team-addons/`, and every
`*/default-add-ons/*` wrapper (see contracts/ for the values each expects):

```bash
for c in chart platform-addons team-addons \
         platform-addons/default-add-ons/* team-addons/default-add-ons/*; do
  helm dependency build "$c"
  helm lint "$c"
done

helm template chart --set clusterName=kind-argocd-playground \
  --set dns=example.com --set environment=local
```

**Expected outcome**: zero lint errors; the parent template emits two
`Application` manifests named `platform-addons` and `team-addons` (User
Story 1, Acceptance Scenario 1; SC-005).

## 2. Stand up a local cluster and Argo CD

```bash
kind create cluster --name argocd-playground
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.4.4/manifests/install.yaml
kubectl -n argocd wait --for=condition=available deploy/argocd-server --timeout=180s
```

**Expected outcome**: `kubectl get pods -n argocd` shows all Argo CD
components `Running`.

## 3. Bootstrap the root Application (one-time manual step)

```bash
kubectl apply -f bootstrap/root-application.yaml
```

**Expected outcome**: `argocd app get root` (after `argocd login`/port-forward)
shows the root app `Synced`; `argocd app get platform-addons` and
`argocd app get team-addons` show up as child apps (User Story 1, Acceptance
Scenario 2).

## 4. Verify platform add-ons

```bash
argocd app get ingress-nginx
argocd app get postgresql-platform
kubectl get svc -n ingress-nginx
```

**Expected outcome**: both `Synced`/`Healthy`; disabling either
`customAddons.platform.*.enable` flag and re-syncing removes only that app
(User Story 2, all Acceptance Scenarios; SC-001).

## 5. Verify team add-ons and isolation

```bash
argocd app get postgresql-team
argocd app get outline
kubectl get svc -n team | grep postgresql
```

**Expected outcome**: `postgresql-team` and `outline` `Synced`/`Healthy`;
`outline`'s rendered `DATABASE_URL` (check via
`argocd app manifests outline | grep DATABASE_URL`) points at
`postgresql-team`, never `postgresql-platform` (User Story 3, Acceptance
Scenario 1 and 3; SC-003).

## 6. Verify Outline reachability

```bash
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -H "Host: outline.kind-argocd-playground.example.com" "http://${INGRESS_IP}/"
```

**Expected outcome**: HTTP response returns the Outline UI or its first-run
setup screen within 5 minutes of `outline` reporting `Healthy` (User Story 3,
Acceptance Scenario 2; SC-002).

## 7. Tear down

```bash
kind delete cluster --name argocd-playground
```

## Reference

- Values contracts: [contracts/parent-to-child-values.md](./contracts/parent-to-child-values.md), [contracts/child-to-leaf-application.md](./contracts/child-to-leaf-application.md)
- Entity shapes: [data-model.md](./data-model.md)
- Open decisions and rationale: [research.md](./research.md)
