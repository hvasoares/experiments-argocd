---
date: 2026-07-07T15:38:00-03:00
researcher: Hugo Soares
git_commit: 97d53a1937687360be485d75d590a2925a5dcdaf
branch: main
repository: add-ons-apps-chart
topic: "Actionable to-do list to replicate add-ons app-of-apps pattern in a new codebase"
tags: [research, add-ons-apps-chart, eks-blueprints-add-ons, did-team-add-ons, argocd, app-of-apps, operators, experiment, todo, ingress-nginx, postgresql, outline]
status: complete
last_updated: 2026-07-07
last_updated_by: Hugo Soares
last_updated_note: "Locked exercise stack — ingress-nginx, Bitnami PostgreSQL, Outline"
---

# Experiment: replicate add-ons app-of-apps pattern (actionable to-do)

Actionable checklist to reproduce the Gympass add-ons pattern in a **fresh codebase**. Each item is sized for one vibecoding session with a clear **done** state.

**Mirrors:** `add-ons-apps-chart` → `did-team-add-ons` / `eks-blueprints-add-ons` → leaf Application → Helm wrapper → upstream chart.

---

## Stack decisions (locked)

Exercise workloads for the scratch experiment — replaces AWS operators with mainstream OSS Helm charts.

| Layer | Choice | Chart / source | Role in experiment |
|-------|--------|----------------|-------------------|
| **Ingress** | [ingress-nginx](https://github.com/kubernetes/ingress-nginx) | `ingress-nginx/ingress-nginx` | Platform add-on — shared cluster edge |
| **Database** | [Bitnami PostgreSQL](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) | `bitnami/postgresql` | Platform + team each get an instance (different namespaces) |
| **Application** | [Outline](https://github.com/outline/outline) | Community / wrapper Helm chart with Postgres URL | Team-owned app; nginx path via Ingress |

### Target topology

```
parent-apps-chart
├── platform-addons
│     ├── ingress-nginx          (namespace: ingress-nginx)
│     └── postgresql-platform    (namespace: platform, Bitnami)
└── team-addons-experiment
      ├── postgresql-team        (namespace: team, Bitnami)
      └── outline                (namespace: team, DB → postgresql-team)
```

### Pattern mapping (Gympass → experiment)

| Gympass concept | Experiment equivalent |
|-----------------|----------------------|
| `gympass-api-gateway-operator` | `ingress-nginx` + `postgresql-platform` (platform leaf apps) |
| `did-api-gateway-operator` | `postgresql-team` + `outline` (team leaf apps) |
| OCI operator wrapper | Helm wrapper under `default-add-ons/` → Bitnami / Outline dependency |
| Different API group / coexistence | Same Outline chart **not** deployed by platform; team-only app in `team` namespace |
| `METRICS_ENABLED` team delta | Team Outline values: e.g. `metrics.enabled: true` vs platform Postgres `metrics.enabled: false` |
| IRSA / AWS IAM | **Skip** in MVP — K8s Secrets for Postgres auth only |

### Wrapper chart pins (fill on scaffold)

| Wrapper path | Upstream dependency |
|--------------|---------------------|
| `default-add-ons/ingress-nginx/` | `ingress-nginx` chart |
| `default-add-ons/postgresql/` | `bitnami/postgresql` |
| `default-add-ons/outline/` | Outline community chart (pin version at scaffold time) |

---

## Phase 0 — Lock decisions (1 session)

1. ~~**Pick the operator you're wrapping**~~  
   **Done:** Bitnami `postgresql`, `ingress-nginx`, Outline (see **Stack decisions** above).

2. **Choose coexistence model**  
   **Done when:** written in README — platform runs ingress + platform Postgres; team runs team Postgres + Outline only (side-by-side, no duplicate Outline on platform).

3. **Choose drift strategy**  
   **Done when:** you picked one — **A** GitHub sync PRs, **B** Argo multi-source (`spec.sources:`), or **manual copy**.

4. **Name the repos**  
   **Done when:** three names exist, e.g. `platform-addons`, `parent-apps-chart`, `team-addons-experiment`.

---

## Phase 1 — Parent app-of-apps (mimics `add-ons-apps-chart`)

5. **Scaffold parent Helm chart**  
   **Done when:** `chart/Chart.yaml`, `chart/values.yaml`, `chart/templates/applications.yaml` exist.

6. **Implement `child-values` helper**  
   **Done when:** `_helpers.tpl` merges parent cluster context (`account`, `region`, `clusterName`, `dns`, …) into each child `valuesObject` (mirror `add-ons-apps.child-values`).

7. **Implement env merge order**  
   **Done when:** `values.yaml` → `values-{env}.yaml` → `values-{cluster}.yaml` deep-merge works via one helper.

8. **Register child apps in `values.yaml`**  
   **Done when:** under `apps:` you have at least `platform-addons` and `team-addons-experiment` with `enabled`, `repoURL`, optional `values`.

9. **Render one Application per `apps` entry**  
   **Done when:** `helm template` outputs Argo `Application` CRs with `spec.source.path: chart` and `helm.valuesObject`.

10. **Smoke-test parent chart locally**  
    **Done when:** `helm template` runs with fake `clusterName` / `account` and prints two child Applications.

---

## Phase 2 — Platform add-ons lib (mimics `eks-blueprints-add-ons`)

11. **Scaffold platform app-of-apps chart**  
    **Done when:** `chart/Chart.yaml`, `chart/templates/_helpers.tpl` (`add-on-path`, `get-environment`), `chart/templates/{priority}/` layout exist.

12. **Add platform leaf Application templates**  
    **Done when:** `templates/` includes gated apps for:
    - `ingress-nginx` (`customAddons.platform.ingressNginx.enable`)
    - `postgresql-platform` (`customAddons.platform.postgresql.enable`)

13. **Add wrapper charts under `default-add-ons/`**  
    **Done when:** each has `Chart.yaml` dependency on upstream + `values.yaml` (ingress-nginx, bitnami/postgresql).

14. **Inline cluster context in Application templates**  
    **Done when:** templates set namespace, ingress class/host hints, Postgres `auth.database` / `auth.username` from `.Values.clusterName`.

15. **Hardcode one platform-only default**  
    **Done when:** e.g. `metrics.enabled: false` on platform Postgres inline `helm.values`.

16. **Smoke-test platform chart**  
    **Done when:** `helm template` emits leaf Applications for `ingress-nginx` and `postgresql-platform`.

---

## Phase 3 — Team add-ons (mimics `did-team-add-ons`)

17. **Scaffold team app-of-apps chart**  
    **Done when:** same shape as platform — `Chart.yaml`, `values.yaml`, `templates/6/`, `default-add-ons/`.

18. **Copy/sync `_helpers.tpl` from platform chart**  
    **Done when:** `add-on-path` resolves `chart/default-add-ons/{team-operator}` in team repo.

19. **Create team wrapper charts**  
    **Done when:**
    - `default-add-ons/postgresql-team/` pins **same** `bitnami/postgresql` chart version as platform
    - `default-add-ons/outline/` pins Outline chart version

20. **Copy platform Postgres wrapper `values.yaml` as base for team Postgres**  
    **Done when:** team Postgres `values.yaml` matches platform defaults; differs by namespace/auth secret name only.

21. **Create team leaf Application templates**  
    **Done when:** templates exist for `postgresql-team` and `outline` with **different**:
    - Argo App names
    - destination namespace (`team`)
    - Postgres credentials / DB name
    - Outline `DATABASE_URL` pointing at team Postgres Service
    - Team-only overlay: e.g. `metrics.enabled: true`, Ingress host `outline.{clusterName}.example.com`

22. **Extract shared partials (if using Option A sync later)**  
    **Done when:** shared tpl holds common Ingress/Postgres env blocks; team templates only add overrides.

23. **Smoke-test team chart**  
    **Done when:** `helm template` emits `postgresql-team` + `outline` Applications; paths point at team repo wrappers.

---

## Phase 4 — Wire parent → children

24. **Point parent at both child repos**  
    **Done when:** `apps.platform-addons.repoURL` and `apps.team-addons-experiment.repoURL` set in parent `values.yaml`.

25. **Add per-cluster enable file**  
    **Done when:** `values-my-cluster.yaml` has `apps.team-addons-experiment.enabled: true` and operator `enable: true`.

26. **Verify values flow end-to-end on paper**  
    **Done when:** you can trace `clusterName` from parent `valuesObject` → child `valuesObject` → leaf Application inline `helm.values`.

---

## Phase 5 — Argo CD bootstrap (minimal cluster)

27. **Install Argo CD (or use existing 3.4.4)**  
    **Done when:** UI/CLI works; version confirmed.

28. **Register Git repos in Argo**  
    **Done when:** parent, platform, and team repos show as connected.

29. **Register Helm repos in Argo**  
    **Done when:** Bitnami repo (`https://charts.bitnami.com/bitnami`) and ingress-nginx repo resolve; `argocd app manifests` doesn't fail on dependencies.

30. **Apply root Application manually (experiment)**  
    **Done when:** one `Application` points at parent chart `chart/` with inline `valuesObject` (`clusterName`, ingress host base, Postgres passwords via secrets).

31. **Confirm child Applications appear**  
    **Done when:** Argo shows `platform-addons` + `team-addons-experiment` as child apps of sync.

32. **Confirm leaf Applications appear**  
    **Done when:** Argo shows `ingress-nginx`, `postgresql-platform`, `postgresql-team`, and `outline`.

---

## Phase 6 — Runtime prerequisites

33. **Create team namespace**  
    **Done when:** `team` namespace exists or `CreateNamespace=true` on leaf apps.

34. **Create Postgres auth secrets**  
    **Done when:** `postgresql-platform` and `postgresql-team` have credentials via K8s Secret or Helm `auth.existingSecret`.

35. **Wire Outline → team Postgres**  
    **Done when:** Outline Deployment has working `DATABASE_URL` (or equivalent env) targeting `postgresql-team` Service DNS.

---

## Phase 7 — Validate behavior

36. **Sync platform leaf apps first**  
    **Done when:** `ingress-nginx` + `postgresql-platform` healthy in Argo; IngressClass available.

37. **Sync team leaf apps**  
    **Done when:** `postgresql-team` + `outline` healthy; Outline pod connects to team Postgres.

38. **Hit Outline via Ingress**  
    **Done when:** `curl -H "Host: outline.<cluster>.example.com" http://<ingress-ip>/` returns Outline UI or setup page.

39. **Confirm platform Postgres isolation**  
    **Done when:** team Outline is **not** using `postgresql-platform` Service (separate DB instance verified).

40. **Check team metrics delta**  
    **Done when:** team Outline (or team Postgres) has metrics enabled per overlay; platform Postgres does not.

---

## Phase 8 — Optional: Option B multi-source (Argo 3.4.4)

41. **Replace team leaf `spec.source` with `spec.sources`**  
    **Done when:** source[0] = platform repo wrapper path (e.g. `default-add-ons/outline`); source[1] = team repo `ref: values`.

42. **Move team overrides to overlay values file**  
    **Done when:** `chart/overlays/outline/values.yaml` holds Ingress host, `DATABASE_URL`, metrics flags.

43. **Run multi-source smoke test**  
    **Done when:** `argocd app manifests` succeeds for `outline` with merged platform chart + team values.

---

## Phase 9 — Optional: Option A sync pipeline

44. **Add `scripts/sync-from-platform.sh`**  
    **Done when:** script updates helpers, Bitnami/ingress-nginx/Outline pins, shared partials from platform repo.

45. **Add `.github/workflows/sync-platform.yaml`**  
    **Done when:** workflow runs script and opens PR on schedule / `workflow_dispatch`.

---

## Phase 10 — Document & hand off

46. **Write experiment README**  
    **Done when:** diagram of `parent → platform/team → ingress-nginx / postgres / outline`, enablement steps, stack table from **Stack decisions**.

47. **Write "bump chart version" runbook**  
    **Done when:** 3-step list — bump Bitnami/Outline pins in wrappers, re-sync or bump multi-source revision, sync cluster.

---

## Suggested vibecoding session order (5 sessions)

| Session | Items |
|---------|--------|
| **1** | 1–4, 5–10 |
| **2** | 11–16 |
| **3** | 17–23, 24–26 |
| **4** | 27–35 |
| **5** | 36–40, then 41–43 *or* 44–45, plus 46–47 |

---

## Minimum viable experiment (cut scope)

Smallest slice that still proves the pattern: **items 5, 8, 9, 17, 19, 21, 24, 27, 30, 33, 37** — parent app-of-apps → team Postgres + Outline (skip ingress-nginx and platform Postgres initially if needed).

**Full stack MVP:** platform deploys **ingress-nginx** + **postgresql-platform**; team deploys **postgresql-team** + **Outline** behind Ingress.

---

## Reference repos in this workspace

| Role | Path / repo |
|------|-------------|
| Parent app-of-apps | `add-ons-apps-chart/` |
| Platform add-ons lib | `eks-blueprints-add-ons/chart/` |
| Team add-ons experiment | `did-team-add-ons/` |
| Platform operator template | `eks-blueprints-add-ons/chart/templates/6/gympass-api-gateway-operator.yaml` |
| Team operator template | `did-team-add-ons/chart/templates/6/did-api-gateway-operator.yaml` |
