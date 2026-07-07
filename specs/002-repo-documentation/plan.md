# Implementation Plan: Reproducible & Applicability-Ready Repo Documentation

**Branch**: `002-repo-documentation` | **Date**: 2026-07-07 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-repo-documentation/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Produce a small, purpose-specific documentation set under `docs/pattern/`
that lets a reader — human or AI assistant (e.g. Cursor) — either (a)
reproduce this repo's Argo CD app-of-apps pattern in a brand-new project
using only the docs, or (b) assess whether/how the pattern applies to a
different, already-existing real-world project. The set links to (never
duplicates) the deeper design artifacts already in
`specs/001-app-of-apps-experiment/`, and captures the real pitfalls hit
while building this repo so they aren't silently lost.

## Technical Context

**Language/Version**: Markdown (CommonMark / GitHub-flavored) — no application code is authored by this feature.

**Primary Dependencies**: None. Content is derived entirely from this repo's own committed artifacts (chart sources under `chart/`, `platform-addons/`, `team-addons/`; `docs/PREREQUISITES.md`; `specs/001-app-of-apps-experiment/*`; `tasks.md`'s rollout notes / resolution log) plus general Argo CD/Helm domain knowledge.

**Storage**: N/A.

**Testing**: No automated test suite — prose isn't unit-testable. Validation is a structured manual review against spec.md's Success Criteria (SC-001–SC-004), scripted as concrete review scenarios in `quickstart.md` (e.g. "hand a cold reader only this doc set, time how long until they can state X").

**Target Platform**: Rendered as plain Markdown files in this git repo; consumed by humans (GitHub/editor preview) and AI coding assistants reading the raw files directly — no doc-site generator or build step.

**Project Type**: Documentation set (the deliverable is documentation, not a running system) — mirrors how `001-app-of-apps-experiment` treated infra-as-code as its "product."

**Performance Goals**: N/A.

**Constraints**: Every new file MUST stay under 200 lines (Constitution Principle III); MUST link to rather than duplicate `specs/001-app-of-apps-experiment/` content (FR-011); MUST be self-contained enough for a fresh reader/agent to use without prior exposure to the conversation history that produced this repo.

**Scale/Scope**: Six new files under `docs/pattern/`, plus one short added section (not a rewrite) linking into it from the existing repo-root `README.md`. No changes to any chart, template, or values file.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. GitOps via Argo CD | No new/changed deployable units or Argo CD `Applications` — pure documentation. | PASS (N/A) |
| II. Helm Lint Gate | No chart files touched. | PASS (N/A) |
| III. 200-Line File Ceiling | Directly applies and is the reason this feature is split into 6 single-purpose files rather than one large document (FR-008). | PASS |
| IV. App-of-Apps Modularity | No chart structure changes. | PASS (N/A) |
| V. Local Verification Before Cluster Sync | No cluster-affecting changes; validation is the manual review process in quickstart.md instead. | PASS (N/A) |

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
docs/
├── PREREQUISITES.md              # existing — tool versions, pinned chart versions
├── runbooks/
│   └── bump-chart-version.md     # existing
└── pattern/                       # NEW — this feature's deliverable
    ├── README.md                  # entry point (US3): what this repo demonstrates,
    │                              #   "reflects commit <sha>" freshness marker,
    │                              #   links to every file below AND to
    │                              #   specs/001-app-of-apps-experiment/*
    ├── architecture.md            # chart hierarchy diagram + value-flow mechanics
    │                              #   (FR-001, FR-002); links to docs/PREREQUISITES.md
    │                              #   for the pinned-dependency list (FR-004)
    ├── library-reuse-pattern.md   # concrete "platform as a library" walkthrough
    │                              #   (FR-003) — the actual files/mechanism used
    ├── reproduction-guide.md      # step-by-step bootstrap sequence for a new,
    │                              #   empty project (FR-005)
    ├── pitfalls.md                # consolidated real bugs hit + fixes (FR-006),
    │                              #   each entry following contracts/pitfall-entry-
    │                              #   schema.md, sourced from tasks.md's resolution log
    └── applicability-guide.md     # fit-signal checklist (FR-007), each entry
                                   #   following contracts/applicability-fit-signal-
                                   #   schema.md

README.md                          # existing repo-root file — gets ONE short added
                                   #   section linking to docs/pattern/README.md;
                                   #   its existing topology diagram/stack table are
                                   #   left as-is (no duplication introduced)
```

**Structure Decision**: New reader-facing documentation lives under
`docs/pattern/` (six single-purpose files + one index), sitting alongside
this repo's existing `docs/` content rather than inside
`specs/002-repo-documentation/` — the `specs/` tree is Spec Kit's own
planning/process trail (useful for provenance), not where a cold reader or
an AI assistant would look for "how does this pattern work." Each
`docs/pattern/*.md` file maps 1:1 to one primary reader intent from spec.md
(architecture/library-reuse-pattern/reproduction-guide → User Story 1,
applicability-guide/pitfalls → User Story 2, README → User Story 3), keeping
every file focused and under the 200-line ceiling.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
