# Feature Specification: Reproducible & Applicability-Ready Repo Documentation

**Feature Branch**: `002-repo-documentation`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "generate documentation for this repo, the goal is
that the documentation be ready by cursor in way that it can either reproduce
this on another project or compare with a real world project"

## Clarifications

### Session 2026-07-07

- Q: Is User Story 2 a structural diff of this repo against a specific
  external real-world Argo CD repo, or an applicability assessment where a
  reader points an AI assistant (e.g. Cursor) at their OWN existing
  real-world project to judge whether/how this pattern could apply there? →
  A: Applicability assessment against the reader's own project — "check
  this repo out, can we apply this on our project?" — not a diff against a
  fixed external example.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reproduce the pattern in a fresh project (Priority: P1)

A developer (or an AI coding assistant such as Cursor, acting on a
developer's behalf) who has never seen this repo wants to stand up the same
Argo CD app-of-apps pattern — parent chart, platform/team tiers, the
"platform as a library" reuse trick, pinned upstream dependencies — in a
brand-new, empty project, using only the generated documentation as the
blueprint. They should not need to reverse-engineer the pattern by reading
every template and values file first.

**Why this priority**: Reproducibility is the primary reason this
documentation is being requested — the playground's whole point was to
rehearse a reusable pattern, and if the pattern can't be reproduced from the
docs, the documentation has failed at its main job.

**Independent Test**: Hand the documentation (and nothing else — no access to
this repo's source) to a reader, and have them list, in order, the
directories/files they'd create and the sequence of setup steps to reach a
working parent → tier → leaf topology. Cross-check that list against this
repo's actual structure and bootstrap sequence.

**Acceptance Scenarios**:

1. **Given** the generated documentation and no other context, **When** a
   reader is asked "what is the chart hierarchy and how does a value flow
   from the parent chart down to a leaf Application," **Then** they can
   answer correctly citing only the documentation.
2. **Given** the generated documentation, **When** a reader is asked to
   reproduce the "platform as a library" reuse pattern (one tier's chart
   reused by another via Argo CD multi-source, with exactly one overridden
   value), **Then** the documentation contains a concrete, copyable example
   of the pattern, not just an abstract description.
3. **Given** the generated documentation, **When** a reader looks for the
   pinned upstream chart dependencies and where their versions are recorded,
   **Then** the documentation names the exact mechanism (not just "check the
   repo").

---

### User Story 2 - Assess whether this pattern applies to an existing real project (Priority: P2)

A developer working in a different, already-existing real-world project
wants to point an AI coding assistant (e.g. Cursor) at this repo and ask, in
effect, "check this out — can we apply this to our project?" The
documentation should let the assistant judge fit against that target
project's own actual structure and stack: which parts of the pattern
(app-of-apps tiering, the "platform as a library" reuse trick, pinned
upstream dependencies, tenant isolation approach) transfer directly, which
need adaptation, and which don't apply — without first reading this entire
repo's source to derive that judgment criteria from scratch.

**Why this priority**: This is the secondary stated goal and depends on User
Story 1's documentation already existing (you can't judge fit against a
pattern you haven't described yet). It requires a reusable applicability
assessment guide, not an audit of one specific named repo — the target
project is whatever the reader brings via Cursor, not fixed at
documentation-authoring time.

**Independent Test**: Give the documentation to a reader/assistant along
with an arbitrary real project (not specified in advance), and confirm they
can produce a per-dimension fit judgment (applies as-is / applies with
adaptation / does not apply, with a one-line reason) using only the
documented guide, without needing clarifying questions about what to assess.

**Acceptance Scenarios**:

1. **Given** the documentation's applicability guide, **When** a reader
   inspects a target project that already uses Argo CD but as a flat set of
   Applications with no tiering, **Then** the guide lets them conclude
   "app-of-apps tiering applies directly, low adaptation risk," citing the
   specific documented fit signal.
2. **Given** the documentation's applicability guide, **When** a reader
   inspects a target project that uses a different GitOps tool (e.g. Flux)
   instead of Argo CD, **Then** the guide distinguishes which parts of the
   pattern are Argo-CD-specific (won't transfer as-is) from which are
   tool-agnostic (the tiering/reuse idea itself, re-implementable elsewhere)
   rather than giving a flat yes/no.
3. **Given** the documentation's "pitfalls encountered" section, **When** a
   reader checks whether their target project's existing setup already
   avoids those same pitfalls (e.g. pinned subchart passwords,
   repo-root-relative Application paths), **Then** they can do so directly
   from the documented list.

---

### User Story 3 - Fast orientation without re-deriving existing design docs (Priority: P3)

A reader who is not deeply familiar with this specific Spec Kit feature
folder wants a single, short entry-point document that orients them (what
this repo is, what pattern it demonstrates, where to look next) and then
points into the existing deeper artifacts (`specs/001-app-of-apps-experiment/`'s
plan, data model, contracts, quickstart) rather than re-explaining everything
those already cover.

**Why this priority**: Without this, the documentation produced for User
Stories 1-2 risks either duplicating (and drifting from) the existing design
docs, or being so terse it fails those stories' goals. This story is about
information architecture, not new content, so it's the lowest priority but
still necessary for the other two to actually work well.

**Independent Test**: A reader who opens only the new top-level entry-point
document can, within a few minutes, state what the repo demonstrates and
correctly navigate to the specific existing doc that answers a follow-up
question (e.g. "where's the values contract for leaf Applications?").

**Acceptance Scenarios**:

1. **Given** the new documentation set, **When** a reader wants the values
   contract for parent-to-child or child-to-leaf Applications, **Then** the
   entry-point document points them at the existing
   `contracts/*.md` files rather than re-stating their contents.
2. **Given** the new documentation set, **When** a reader wants to know what
   actually broke and was fixed while building this (the Bitnami/community
   chart password-regeneration issue, the repo-root-relative path
   requirement, the values-nesting-under-subchart-name mistake, Outline's
   canonical-URL/port schema restriction), **Then** the documentation
   surfaces all of them in one place rather than requiring a full read of
   `tasks.md`'s rollout notes.

---

### Edge Cases

- What happens when the documentation is read by someone with zero
  Kubernetes/Helm/Argo CD background? It should define each pattern-specific
  term (app-of-apps, leaf Application, multi-source values reuse) at first
  use rather than assuming prior familiarity, without turning into a full
  Kubernetes tutorial.
- What happens if this repo's structure changes after the documentation is
  generated (e.g. a new tier or addon is added)? The documentation is a
  point-in-time artifact, not a live-generated one; staleness risk is
  accepted and should be explicitly called out (e.g. a "generated as of
  commit X" marker) rather than silently presented as always-current.
- What happens when the target project being assessed uses a fundamentally
  different GitOps tool (Flux, plain Kustomize) instead of Argo CD? The
  applicability guide should note which fit signals are Argo-CD-specific vs.
  pattern-general (app-of-apps, tiered ownership, drift-minimization via
  reuse) so it degrades gracefully to "the idea transfers, the mechanism
  doesn't" rather than becoming inapplicable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The documentation MUST describe the full chart hierarchy
  (parent → platform-addons/team-addons → leaf Application → upstream
  dependency) with a diagram, sufficient for a reader to redraw it from
  memory afterward.
- **FR-002**: The documentation MUST describe how values flow and merge at
  each hand-off (parent→child, child→leaf), citing the specific mechanism
  used (Sprig `mergeOverwrite`, Argo CD `valuesObject`/`valueFiles`) rather
  than describing it only in the abstract.
- **FR-003**: The documentation MUST include a concrete, reproducible
  walkthrough of the "platform as a library" reuse pattern: one tier's chart
  reused by another tier via Argo CD multi-source, with the override
  mechanism and file(s) involved named explicitly.
- **FR-004**: The documentation MUST enumerate every pinned upstream chart
  dependency used in this repo and name where its version is recorded.
- **FR-005**: The documentation MUST include a step-by-step reproduction
  sequence (bootstrap order: tooling → cluster → root Application → tiers →
  leaves) a reader can follow in a new, empty project.
- **FR-006**: The documentation MUST include a dedicated "pitfalls
  encountered" section capturing every real bug found while building and
  operating this repo (as recorded in `tasks.md`'s rollout notes /
  resolution log), not just the clean end-state design.
- **FR-007**: The documentation MUST provide an applicability assessment
  guide — a named set of fit signals/prerequisites (e.g. existing GitOps
  tool in use, multi-tenant/multi-team structure, monorepo acceptability,
  existing Helm chart maturity) with the tradeoff or adaptation each implies
  — usable by a reader (or an AI assistant such as Cursor) to judge, for any
  given real-world project brought to it, which parts of this pattern apply
  as-is, apply with adaptation, or don't apply — without requiring a
  specific target project to be named or assessed as part of this feature.
- **FR-008**: The documentation MUST be organized as a small set of
  purpose-specific files with one short entry-point/index document, rather
  than one large document, consistent with this repo's 200-line file
  ceiling (Constitution Principle III).
- **FR-009**: The documentation MUST define pattern-specific terminology
  (app-of-apps, leaf Application, multi-source values reuse) at first use.
- **FR-010**: The documentation MUST record the point in time (commit/date)
  it reflects, so staleness is visible rather than assumed away.
- **FR-011**: The documentation MUST link to, rather than duplicate, the
  existing deeper design artifacts already present in
  `specs/001-app-of-apps-experiment/` (plan.md, data-model.md, contracts/,
  quickstart.md, research.md).

### Key Entities

- **Documentation Set**: The small collection of new Markdown files this
  feature produces, plus the entry-point/index document that ties them
  together and links out to existing `specs/001-app-of-apps-experiment/`
  artifacts.
- **Reproduction Guide**: The step-by-step, bootstrap-ordered walkthrough
  satisfying FR-005, aimed at standing up the pattern in a new project.
- **Applicability Assessment Guide**: The fit-signal-by-fit-signal checklist
  satisfying FR-007, aimed at judging whether/how this pattern applies to a
  reader's own real-world project — not a structural diff against one fixed
  reference repo.
- **Pitfalls Register**: The consolidated list of real issues encountered
  and fixed (FR-006), each traceable back to its entry in `tasks.md`'s
  rollout notes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reader unfamiliar with this repo can correctly describe the
  full chart hierarchy and one complete parent-to-leaf value flow within 5
  minutes, using only the generated documentation.
- **SC-002**: A reader can list the concrete steps to reproduce the
  pattern's skeleton (chart directories, values contracts, one working leaf
  app) in a new empty project within 15 minutes, using only the generated
  documentation.
- **SC-003**: 100% of the distinct pitfalls recorded in `tasks.md`'s
  rollout notes / resolution log appear in the documentation's pitfalls
  section.
- **SC-004**: A reader can produce a per-dimension applicability judgment
  (applies as-is / applies with adaptation / does not apply, with a
  one-line rationale) for an arbitrary real-world project using only the
  documented applicability guide, without asking a clarifying question
  about what to assess.

## Assumptions

- The documentation set is produced as static Markdown files committed to
  this repo (e.g. under a `docs/` location decided at planning time), not a
  generated/rendered site or external tool.
- "Ready by cursor" is read as "readable by Cursor" (or any similar AI
  coding assistant) — i.e., the documentation should be well-structured,
  self-contained Markdown (clear headers, explicit facts, minimal reliance
  on implicit repo-wide context) rather than requiring a special format or
  tool integration.
- This feature produces the applicability assessment guide and reproduction
  guide themselves; it does not assess any specific named real-world
  project, since the target is whatever project a reader brings via Cursor
  later, not fixed at documentation-authoring time (see Clarifications).
- The documentation targets a reader with general software engineering
  background but not necessarily prior Kubernetes/Helm/Argo CD exposure,
  per the Edge Cases above.
- Existing artifacts in `specs/001-app-of-apps-experiment/` remain the
  source of truth for fine-grained contracts/data-model detail; the new
  documentation set is additive (orientation, reproduction, comparison), not
  a replacement.
