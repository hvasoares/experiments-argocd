---

description: "Task list template for feature implementation"
---

# Tasks: Argo CD App-of-Apps Experiment

**Input**: Design documents from `/specs/001-app-of-apps-experiment/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Not explicitly requested. Validation is via `helm lint`/`helm template` and the `quickstart.md` scenarios instead of a unit-test suite — appropriate for a Helm/Argo CD chart repo.

**Organization**: Tasks are grouped by user story. Ordering below is a topological sort of the full task DAG — a task never appears before something it depends on — and every task not on a dependency chain with an already-queued task is marked `[P]` so it can run alongside its peers.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Paths are relative to the repo root (see plan.md § Project Structure)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold every chart directory and support script so later phases only ever add content, never create new top-level paths.

- [X] T001 [P] Scaffold parent chart skeleton: `chart/Chart.yaml`, `chart/values.yaml`
- [X] T002 [P] Scaffold platform-addons chart skeleton: `platform-addons/Chart.yaml`, `platform-addons/values.yaml`
- [X] T003 [P] Scaffold team-addons chart skeleton: `team-addons/Chart.yaml`, `team-addons/values.yaml`
- [X] T004 [P] Create `bootstrap/root-application.yaml` placeholder (empty `Application` shell, path not yet wired)
- [X] T005 [P] Verify/install local CLI tooling (`helm`, `kind`, `kubectl`, `argocd`) and record versions in `docs/PREREQUISITES.md`
- [X] T006 [P] Add upstream Helm repo registration script `scripts/setup-helm-repos.sh` (`helm repo add ingress-nginx`, `helm repo add bitnami`, `helm repo update`)

**Checkpoint**: All chart directories exist; tooling and upstream repos are usable locally.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared helpers, version pins, and cluster bootstrap that every user story phase depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T007 [P] Implement `chart.mergedValues` helper (base → env → cluster deep-merge via Sprig `mergeOverwrite`) in `chart/templates/_helpers.tpl` (depends on: T001)
- [X] T008 [P] Implement `add-on-path`/`get-environment` helpers in `platform-addons/templates/_helpers.tpl` (depends on: T002)
- [X] T009 [P] Implement the same `add-on-path`/`get-environment` helpers in `team-addons/templates/_helpers.tpl`, mirroring T008's shape (depends on: T003)
- [X] T010 [P] Resolve and record pinned upstream chart versions (ingress-nginx, bitnami/postgresql, Outline chart) via `helm search repo <chart> --versions` and append them to `docs/PREREQUISITES.md` (depends on: T005, T006)
- [X] T011 [P] Stand up a local `kind` cluster and install Argo CD 3.4.4, scripted in `scripts/bootstrap-cluster.sh` (depends on: T005)

**Checkpoint**: Foundation ready — User Stories 1, 2, and 3 can now proceed fully in parallel.

---

## Phase 3: User Story 1 - Stand up the app-of-apps topology (Priority: P1) 🎯 MVP

**Goal**: A root Argo CD Application, once synced, renders the parent chart into `platform-addons` and `team-addons` child Applications with no manual `kubectl apply` beyond bootstrap.

**Independent Test**: `helm template chart` with representative values emits exactly two child `Application` manifests; applying the root Application to a cluster shows both children `Synced`/`Healthy`.

### Implementation for User Story 1

- [X] T012 [P] [US1] Define the `apps` registry (`platform-addons`, `team-addons` entries: `enabled`, `repoURL`, `path`, `targetRevision`) in `chart/values.yaml` (depends on: T001)
- [X] T013 [P] [US1] Implement `chart/values-{env}.yaml` and `chart/values-{cluster}.yaml` overlay examples (depends on: T001)
- [X] T014 [US1] Implement `chart/templates/applications.yaml` to render one Argo CD `Application` per `apps` entry via `chart.mergedValues` (depends on: T007, T012)
- [X] T015 [US1] Wire `bootstrap/root-application.yaml` to point at `chart/` with sample `clusterName`/`dns`/`environment` values (depends on: T004, T014)
- [X] T016 [US1] Validate: `helm dependency build && helm lint && helm template chart` (quickstart.md step 1) confirms two child Application manifests are emitted (depends on: T014)

**Checkpoint**: User Story 1 is fully functional and testable independently (chart-only, no cluster required).

---

## Phase 4: User Story 2 - Platform add-ons are deployed cluster-wide (Priority: P2)

**Goal**: The platform-addons chart renders `ingress-nginx` and `postgresql-platform` as independently toggleable leaf Applications with platform-only defaults.

**Independent Test**: `helm template platform-addons` with both enable flags `true` emits exactly two leaf Applications in their documented namespaces; flipping either flag to `false` removes only that Application.

### Implementation for User Story 2

- [X] T017 [P] [US2] Create `platform-addons/default-add-ons/ingress-nginx/Chart.yaml` and `values.yaml`, pinned per `docs/PREREQUISITES.md` (depends on: T010)
- [X] T018 [P] [US2] Create `platform-addons/default-add-ons/postgresql/Chart.yaml` and `values.yaml`, pinned per `docs/PREREQUISITES.md`, with `metrics.enabled: false` (depends on: T010)
- [X] T019 [P] [US2] Implement `platform-addons/templates/addons/ingress-nginx.yaml` leaf Application gated by `customAddons.platform.ingressNginx.enable` (depends on: T008, T017)
- [X] T020 [P] [US2] Implement `platform-addons/templates/addons/postgresql.yaml` leaf Application gated by `customAddons.platform.postgresql.enable` (depends on: T008, T018)
- [X] T021 [US2] Populate `customAddons.platform.*` toggle entries (`enable`, `namespace`, `chartPath`, `values`) in `platform-addons/values.yaml` (depends on: T019, T020)
- [X] T022 [US2] Validate: `helm dependency build && helm lint && helm template platform-addons` (quickstart.md step 1) confirms both leaf Applications render, and toggling either flag off removes only that one (depends on: T021)

**Checkpoint**: User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 - Team app is deployed with its own isolated database (Priority: P3)

**Goal**: The team-addons chart renders `postgresql-team` and `outline` as leaf Applications, fully isolated from the platform Postgres instance, with Outline reachable via ingress.

**Independent Test**: `helm template team-addons` shows `outline`'s database connection value referencing `postgresql-team`, never `postgresql-platform`; on a synced cluster the Outline UI is reachable via its ingress hostname.

### Implementation for User Story 3

- [X] T023 [P] [US3] Create `team-addons/default-add-ons/postgresql/Chart.yaml` and `values.yaml`, pinned to the **same** version recorded in `docs/PREREQUISITES.md` for T018, with distinct `namespace: team` and `metrics.enabled: true` (depends on: T010)
- [X] T024 [P] [US3] Create `team-addons/default-add-ons/outline/Chart.yaml` and `values.yaml`, pinned per `docs/PREREQUISITES.md`, with Ingress host template and `DATABASE_URL` pointing at the `postgresql-team` Service (depends on: T010)
- [X] T025 [P] [US3] Implement `team-addons/templates/addons/postgresql.yaml` leaf Application gated by `customAddons.team.postgresql.enable` (depends on: T009, T023)
- [X] T026 [P] [US3] Implement `team-addons/templates/addons/outline.yaml` leaf Application gated by `customAddons.team.outline.enable` (depends on: T009, T024)
- [X] T027 [US3] Populate `customAddons.team.*` toggle entries in `team-addons/values.yaml` (depends on: T025, T026)
- [X] T028 [US3] Validate: `helm dependency build && helm lint && helm template team-addons` (quickstart.md step 1); grep the rendered `outline` Application to confirm its `DATABASE_URL` references `postgresql-team` and never `postgresql-platform` (depends on: T027)

**Checkpoint**: All three user stories are independently functional at the chart-authoring level (no live cluster required for any of them).

---

## Phase 6: Polish & Cross-Cutting Concerns (Integration)

**Purpose**: Documentation, repeatability tooling, and the one true end-to-end cluster validation that exercises all three stories together.

- [X] T029 [P] Write experiment `README.md` with topology diagram and the stack table from spec.md
- [X] T030 [P] Write the "bump chart version" runbook in `docs/runbooks/bump-chart-version.md`
- [X] T031 [P] Add `scripts/lint-all.sh` wrapping `helm dependency build && helm lint && helm template` across every chart in the repo, for repeatable local checks (Constitution Principle II)
- [X] T032 Apply `bootstrap/root-application.yaml` to the cluster from T011 and confirm `platform-addons`/`team-addons` reach `Synced`/`Healthy` (quickstart.md steps 2-3) (depends on: T011, T015, T016, T022, T028)
- [X] T033 Confirm `ingress-nginx` and `postgresql-platform` reach `Synced`/`Healthy` on the live cluster (quickstart.md step 4) (depends on: T032)
- [X] T034 Confirm `postgresql-team` and `outline` reach `Synced`/`Healthy`, curl Outline via its ingress hostname, and confirm it resolves against `postgresql-team` (not `postgresql-platform`) live, not just statically (quickstart.md steps 5-6) (depends on: T032, T033)
- [ ] T035 Tear down the local cluster: `kind delete cluster --name argocd-playground` (quickstart.md step 7) (depends on: T034) — **on hold**: cluster left running with a working demo; tear down whenever you're done exploring it.

**Resolution log (2026-07-07)**: T032-T034 initially failed for three stacked reasons, fixed in sequence: (1) `repoURL` was still the `example.com` placeholder — fixed by pushing this repo to `github.com/hvasoares/experiments-argocd` and rewiring `chart/values.yaml` + `bootstrap/root-application.yaml` + all four leaf Application templates to the real URL; (2) `platform-addons`' `add-on-path` helper and both charts' `customAddons.*.chartPath` values were missing their own chart-name prefix (Argo resolves `spec.source.path` from the repo root, not the parent chart's directory) — fixed to `{platform,team}-addons/default-add-ons/<addon>`; (3) none of the four leaf Applications set `syncOptions: [CreateNamespace=true]`, so every sync failed at the PreSync namespace-RBAC step — added to all four; (4) `team-addons/default-add-ons/postgresql` never set `auth.database: outline`, so Outline crash-looped on `database "outline" does not exist` — fixed, plus the already-initialized PVC had to be deleted and recreated since Postgres only runs initdb once. All four Applications now `Synced`/`Healthy` except `postgresql-team`'s Secret, which is a known, harmless Bitnami-chart cosmetic diff (its template re-randomizes a password value on every render; `selfHeal` is off for this app so nothing is actually rewritten). Outline is reachable via ingress (HTTP 200 over HTTPS with the Host header) and its live `PGHOST` env var resolves to `postgresql-team.team.svc.cluster.local`, confirmed never `postgresql-platform`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — all 6 tasks start immediately, in parallel.
- **Foundational (Phase 2)**: Each task depends only on its own Phase 1 stub/tooling task — all 5 tasks run in parallel once their specific prerequisite lands (see per-task `depends on`).
- **User Stories (Phase 3-5)**: Each story depends only on Foundational — **US1, US2, and US3 have zero dependencies on each other** and run fully in parallel.
- **Polish/Integration (Phase 6)**: T029-T031 are documentation/tooling and only need the repo to exist (parallel with everything). T032-T035 form a strict sequential tail that depends on every story's chart-authoring being done plus the cluster (T011).

### Topological Task Graph

```text
T001 ─┬─> T007 ─┬─> T012 ─┐
      │         │         ├─> T014 ─> T015 ─> T016 ─┐
T004 ─┼─────────┼─> T013 ─┘                          │
      │         │                                    │
T002 ─┼─> T008 ─┬─> T019 ─┐                           │
      │         │         ├─> T021 ─> T022 ──────────┤
T005 ─┼─> T010 ─┼─> T017 ─┘                           │
      │         │                                    │
T006 ─┘         ├─> T020 (needs T018 too)             │
                │                                     │
T003 ─┬─> T009 ─┬─> T025 ─┐                           │
      │         │         ├─> T027 ─> T028 ──────────┤
      │         ├─> T023 ─┘                           │
      │         │                                     │
      │         ├─> T026 ─ (needs T024 too)           │
      │         └─> T024 ──────────────────────────── │
      │                                                │
T005 ─┴─> T011 ─────────────────────> T032 <───────────┘
                                        │
                                        v
                                       T033 ─> T034 ─> T035

T029, T030, T031: parallel, depend only on repo existing (any point after Phase 1)
```

### Parallel Opportunities

- **Phase 1**: T001-T006 — all 6 in parallel.
- **Phase 2**: T007-T011 — all 5 in parallel (each gated only by its own Phase 1 input).
- **Phase 3 (US1)**: T012, T013 in parallel; then T014 → T015 → T016.
- **Phase 4 (US2)**: T017, T018 in parallel; then T019, T020 in parallel; then T021 → T022.
- **Phase 5 (US3)**: T023, T024 in parallel; then T025, T026 in parallel; then T027 → T028.
- **Across stories**: once Phase 2 is done, the entire US1 chain, US2 chain, and US3 chain run concurrently — a 3-person team can take one story each with zero coordination until Phase 6.
- **Phase 6**: T029, T030, T031 run in parallel with each other and with Phases 3-5; T032-T035 are the only fully serial segment in the whole plan (live-cluster integration, inherently sequential).

---

## Parallel Example: Foundational → All Three Stories

```bash
# After Phase 1 completes, launch all of Phase 2 together:
Task: "chart.mergedValues helper in chart/templates/_helpers.tpl"
Task: "add-on-path/get-environment helpers in platform-addons/templates/_helpers.tpl"
Task: "add-on-path/get-environment helpers in team-addons/templates/_helpers.tpl"
Task: "Resolve pinned upstream versions into docs/PREREQUISITES.md"
Task: "Bootstrap local kind cluster + Argo CD in scripts/bootstrap-cluster.sh"

# Once Phase 2 completes, launch all three user story chains together:
Task: "US1: chart/values.yaml apps registry + applications.yaml"
Task: "US2: platform-addons wrapper charts + leaf Application templates"
Task: "US3: team-addons wrapper charts + leaf Application templates"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (all 5 tasks — cheap, all parallel)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: `helm template chart` renders both child Applications
5. This alone proves the core app-of-apps mechanic without needing the leaf workloads finished

### Incremental Delivery

1. Setup + Foundational → foundation ready (fast, fully parallel)
2. US1 → validate independently → parent topology proven (MVP)
3. US2 and US3 in parallel → validate independently → both tenants' charts proven
4. Phase 6 integration tail → the one moment everything is proven together live

### Parallel Team Strategy

With three contributors:

1. Everyone completes Setup + Foundational together (fast — mostly independent files)
2. Split: Contributor A → US1, Contributor B → US2, Contributor C → US3 — no file overlap, no coordination needed
3. Whoever finishes first can start Phase 6's T029-T031 (docs/tooling) while others finish
4. Regroup for the Phase 6 integration tail (T032-T035), which is inherently a single-track live-cluster exercise

---

## Notes

- Every `[P]` task in this file touches a different file than every other currently-queued `[P]` task — verified pairwise, not just asserted.
- `[Story]` labels map tasks to spec.md's US1/US2/US3 for traceability.
- No task creates a new top-level chart directory outside Phase 1 — later phases only add files inside directories Phase 1 already created.
- Commit after each task or logical group (Constitution Principle II expects `helm lint`-clean state at each commit).
- The only genuinely sequential segment is Phase 6's T032-T035 — everything else is parallelizable by design.
