---

description: "Task list template for feature implementation"
---

# Tasks: Reproducible & Applicability-Ready Repo Documentation

**Input**: Design documents from `/specs/002-repo-documentation/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Not requested. This feature's "product" is documentation; validation is the manual review process scripted in `quickstart.md` (see each phase's Validate task), not an automated test suite.

**Organization**: Tasks are grouped by user story. Within a story, files that only need to exist (not need each other's content) are marked `[P]`; a story's own validation task always comes last and is never parallel.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Paths are relative to the repo root (see plan.md § Project Structure)

**Scope note**: Per explicit instruction alongside this task-generation run,
User Story 3 (fast orientation) is extended with a concrete mechanism beyond
what spec.md itself spells out: a root `CLAUDE.md` index of every top-level
project directory, plus a per-directory `CLAUDE.md` in each one. This reuses
a convention already present in this repo (`CLAUDE.md`'s existing SPECKIT
block) rather than introducing a new one, and serves the same "fast
orientation for a reader or AI agent" goal US3 already covers — no spec.md
change was needed, but flagging the addition here for traceability.

---

## Phase 1: Setup

**Purpose**: Create the one new directory this feature needs.

- [X] T001 [P] Create the `docs/pattern/` directory (no naming conflict with existing `docs/PREREQUISITES.md` / `docs/runbooks/`)

**Checkpoint**: `docs/pattern/` exists and is empty.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Two facts every later authoring task needs a stable, agreed-on answer for.

**⚠️ CRITICAL**: No content-authoring task can begin until this phase is complete

- [X] T002 [P] Record the current commit SHA and date for the freshness marker (`git rev-parse --short HEAD` + today's date), to be used verbatim in `docs/pattern/README.md` (T018)
- [X] T003 [P] Reconcile the definitive pitfalls list against `specs/001-app-of-apps-experiment/tasks.md`'s rollout notes / resolution log (the 6 known entries in data-model.md § Pitfalls Register are a starting point, not a final list — verify against the actual file)

**Checkpoint**: Freshness marker text and the final pitfalls list both exist and are agreed; all user story phases can now proceed in parallel.

---

## Phase 3: User Story 1 - Reproduce the pattern in a fresh project (Priority: P1) 🎯 MVP

**Goal**: A reader with no prior exposure to this repo can redraw the chart hierarchy, reproduce the library-reuse trick, and list the bootstrap steps for a new project, using only the docs.

**Independent Test**: Hand `architecture.md` + `library-reuse-pattern.md` + `reproduction-guide.md` (and nothing else) to a reader; confirm they pass quickstart.md scenarios 1-3.

### Implementation for User Story 1

- [X] T004 [P] [US1] Write `docs/pattern/architecture.md`: chart hierarchy diagram (FR-001), value-flow mechanics naming `chart.mergedValues`/Argo CD `valuesObject` (FR-002), pinned-dependency index linking to `docs/PREREQUISITES.md` (FR-004), pattern terminology defined at first use (FR-009) (depends on: T001)
- [X] T005 [P] [US1] Write `docs/pattern/library-reuse-pattern.md`: the concrete `postgresql-team` multi-source walkthrough — `spec.sources`, the `$values` ref source, `team-addons/overlays/postgresql/values.yaml`'s one override, where tenant-identity fields live instead (FR-003), per data-model.md § Library Reuse Pattern (depends on: T001)
- [X] T006 [US1] Write `docs/pattern/reproduction-guide.md`: ordered bootstrap sequence (tooling → repos → parent chart → helpers → tiers → leaves → cluster → root Application → sync), framed as building in a new empty project (FR-005), linking to `pitfalls.md`'s eventual location so a builder can avoid repeating them (depends on: T004, T005)
- [X] T007 [US1] Validate US1: run quickstart.md scenarios 1-3 against T004-T006 (depends on: T006)

**Checkpoint**: User Story 1 is fully functional and testable independently.

---

## Phase 4: User Story 2 - Assess applicability to an existing real project (Priority: P2)

**Goal**: A reader can produce a per-dimension applicability verdict for an arbitrary real-world project, and check it against every pitfall this repo actually hit, using only the docs.

**Independent Test**: Hand `applicability-guide.md` + `pitfalls.md` (and nothing else) to a reader along with any project description; confirm they pass quickstart.md scenarios 4-5.

### Implementation for User Story 2

- [X] T008 [P] [US2] Write `docs/pattern/pitfalls.md`: one entry per item in T003's reconciled list, each following `contracts/pitfall-entry-schema.md` (Symptom/Root cause/Fix/Where fixed) (FR-006, SC-003) (depends on: T003)
- [X] T009 [P] [US2] Write `docs/pattern/applicability-guide.md`: fit signals (existing GitOps tool, multi-tenant structure, monorepo acceptability, chart maturity), each following `contracts/applicability-fit-signal-schema.md`, explicitly separating Argo-CD-specific from pattern-general signals (FR-007, Edge Cases) (depends on: T004)
- [X] T010 [US2] Validate US2: run quickstart.md scenarios 4-5 against T008-T009 (depends on: T008, T009)

**Checkpoint**: User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 - Fast orientation without re-deriving existing design docs (Priority: P3)

**Goal**: A reader can orient from one short entry-point document (or a per-directory `CLAUDE.md`) and correctly navigate to the specific existing doc or contract that answers a follow-up question.

**Independent Test**: Hand only `docs/pattern/README.md` (or only one directory's `CLAUDE.md`) to a reader; confirm they pass quickstart.md scenario 6.

### Implementation for User Story 3

- [X] T011 [P] [US3] Create `bootstrap/CLAUDE.md`: what this directory is (the one-time root Application manifest), links to `docs/pattern/reproduction-guide.md`
- [X] T012 [P] [US3] Create `chart/CLAUDE.md`: parent app-of-apps chart — `applications.yaml`, `chart.mergedValues` helper, `values-{env}/{cluster}` overlays; links to `docs/pattern/architecture.md`
- [X] T013 [P] [US3] Create `platform-addons/CLAUDE.md`: platform tier chart — ingress-nginx + postgresql wrapper charts, the base `team-addons` reuses as a library; links to `docs/pattern/library-reuse-pattern.md`
- [X] T014 [P] [US3] Create `team-addons/CLAUDE.md`: team tier chart — outline + postgresql reused via Argo CD multi-source, `overlays/`; links to `docs/pattern/library-reuse-pattern.md`
- [X] T015 [P] [US3] Create `docs/CLAUDE.md`: index of `PREREQUISITES.md`, `runbooks/`, `pattern/`; points into `docs/pattern/README.md`
- [X] T016 [P] [US3] Create `scripts/CLAUDE.md`: what each script does (`setup-helm-repos.sh`, `bootstrap-cluster.sh`, `lint-all.sh`)
- [X] T017 [US3] Update root `CLAUDE.md`: add an index table of all six project directories (name, one-line purpose, link to its own `CLAUDE.md`), alongside the existing SPECKIT block (depends on: T011, T012, T013, T014, T015, T016)
- [X] T018 [US3] Write `docs/pattern/README.md`: entry point — what this repo demonstrates, freshness marker from T002, links to every `docs/pattern/*.md` file and to `specs/001-app-of-apps-experiment/{plan.md,data-model.md,contracts/,quickstart.md,research.md}` (FR-011) (depends on: T002, T004, T005, T006, T008, T009)
- [X] T019 [P] [US3] Add one short "Pattern documentation" section to the existing root `README.md` linking to `docs/pattern/README.md`, without touching its existing topology diagram/stack table (depends on: T018)
- [X] T020 [US3] Validate US3: run quickstart.md scenario 6 against T017-T019 (depends on: T017, T018, T019)

**Checkpoint**: All three user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Whole-set consistency and final sign-off, once every story's content exists.

- [X] T021 [P] Cross-link consistency pass: verify every relative link across `docs/pattern/*.md`, root `README.md`, root `CLAUDE.md`, and the six per-directory `CLAUDE.md` files actually resolves (depends on: T004-T020)
- [X] T022 Final sign-off: run quickstart.md's full 7-scenario review pass end-to-end, including `wc -l docs/pattern/*.md` to confirm the 200-line ceiling (Constitution Principle III) (depends on: T021)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 only, no dependencies.
- **Foundational (Phase 2)**: T002, T003 — both depend only on T001 (the directory existing) and run in parallel.
- **User Stories (Phase 3-5)**: Each story depends only on Foundational — **US1, US2, and US3 have zero dependencies on each other** and run fully in parallel. (Cross-links between stories' files, e.g. reproduction-guide.md → pitfalls.md, are written by path/convention per data-model.md and only actually verified in the Polish phase — see Notes.)
- **Polish (Phase 6)**: Depends on every story's content existing.

### Topological Task Graph

```text
T001 ─┬─> T002 ─┐
      │         ├─> T018 ─> T019 ─┐
      └─> T003 ─┼─> T008 ─┐       │
                │         ├─> T010┤
      T004 ─────┼─> T009 ─┘       │
      T005 ─┐   │                 │
            ├─> T006 ─> T007      │
      T004 ─┘                     │
                                  │
T011,T012,T013,T014,T015,T016 ────┼─> T017 ──> T020 ─┤
                                                       │
                                                       v
                                              T021 ─> T022
```

### Parallel Opportunities

- **Phase 1-2**: T001, then T002/T003 in parallel.
- **Phase 3 (US1)**: T004, T005 in parallel; then T006; then T007.
- **Phase 4 (US2)**: T008, T009 in parallel; then T010.
- **Phase 5 (US3)**: T011-T016 all in parallel; then T017; then T018; then T019; then T020.
- **Across stories**: once Foundational is done, the entire US1 chain, US2 chain, and US3 chain run concurrently — three contributors could take one story each.
- **Phase 6**: T021 then T022, the only fully serial tail (needs everything else done first).

---

## Parallel Example: Foundational → All Three Stories

```bash
# After T001, launch T002 and T003 together:
Task: "Record commit SHA + date for freshness marker"
Task: "Reconcile pitfalls list against 001's tasks.md"

# Once Foundational completes, launch all three story chains together:
Task: "US1: architecture.md + library-reuse-pattern.md + reproduction-guide.md"
Task: "US2: pitfalls.md + applicability-guide.md"
Task: "US3: six per-directory CLAUDE.md files + root CLAUDE.md index + docs/pattern/README.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 + 2 (fast, two small facts to record)
2. Complete Phase 3 (US1)
3. **STOP and VALIDATE**: quickstart.md scenarios 1-3 pass
4. This alone delivers the primary stated goal — reproducibility — without needing the applicability guide or CLAUDE.md indexing finished

### Incremental Delivery

1. Setup + Foundational → ready (fast)
2. US1 → validate → reproducibility proven (MVP)
3. US2 and US3 in parallel → validate → applicability assessment and fast orientation both proven
4. Phase 6 → the one pass that confirms every cross-link actually resolves and every file fits the line ceiling

### Parallel Team Strategy

With three contributors: everyone completes Setup + Foundational together, then Contributor A takes US1, B takes US2, C takes US3 (six small `CLAUDE.md` files plus the entry point) — no file overlap, no coordination needed until Phase 6's cross-link pass.

---

## Notes

- Every `[P]` task touches a different file than every other currently-queued `[P]` task.
- Files in one story are allowed to contain a relative link to a file another story produces (e.g. `reproduction-guide.md` → `pitfalls.md`), written by the agreed path from data-model.md; Phase 6's T021 is what actually verifies every such link resolves, so stories stay independently authorable without a hard cross-story dependency.
- No task creates a new top-level repo directory beyond `docs/pattern/` (T001) — the six `CLAUDE.md` files (T011-T016) are added to directories that already exist.
- The only genuinely sequential segment is Phase 6 (T021 → T022) — everything else is parallelizable by design.
