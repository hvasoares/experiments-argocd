# Research: Reproducible & Applicability-Ready Repo Documentation

No `[NEEDS CLARIFICATION]` markers remained after `/speckit-clarify` (see
spec.md's Clarifications section), so this phase focuses on the concrete
authoring/structure decisions needed before writing begins.

## Where the documentation lives

- **Decision**: New files go under `docs/pattern/`, sitting alongside this
  repo's existing `docs/PREREQUISITES.md` and `docs/runbooks/`.
- **Rationale**: `specs/002-repo-documentation/` (this feature's own folder)
  is Spec Kit's planning/process trail — useful for provenance, not where a
  cold reader or an AI assistant like Cursor would naturally look for "how
  does this pattern work, can I reuse it." `docs/` already exists as this
  repo's reader-facing documentation location.
- **Alternatives considered**: Putting everything inside
  `specs/002-repo-documentation/` (rejected — mixes process artifacts with
  the actual product deliverable, poor discoverability); adding several new
  top-level `*.md` files at the repo root (rejected — root is reserved for
  the existing operational `README.md`, this would clutter it).

## File granularity

- **Decision**: Six single-purpose files (`README.md` index +
  `architecture.md`, `library-reuse-pattern.md`, `reproduction-guide.md`,
  `pitfalls.md`, `applicability-guide.md`) rather than one large document.
- **Rationale**: Directly required by FR-008 and Constitution Principle III
  (200-line ceiling). Each file maps 1:1 to a specific reader intent from
  spec.md's user stories, so a reader chasing one goal (e.g. "just show me
  the reproduction steps") doesn't have to read unrelated sections.
- **Alternatives considered**: One `PATTERN.md` mega-doc (rejected — would
  either blow the line limit or force shallow coverage of each topic);
  splitting further per-addon (e.g. a separate file per leaf app) (rejected
  as over-fragmentation — the pattern is the same across addons, only the
  library-reuse-pattern.md walkthrough needs one concrete example).

## Root README.md treatment

- **Decision**: Add exactly one short new section to the existing root
  `README.md` linking into `docs/pattern/README.md`; do not rewrite or
  duplicate its existing topology diagram / stack table (already authored
  in the `001-app-of-apps-experiment` feature).
- **Rationale**: Applies the same "link, don't duplicate" principle (FR-011)
  recursively to this repo's own root README, not just to
  `specs/001-app-of-apps-experiment/`.
- **Alternatives considered**: Rewriting the root README around the new
  pattern docs (rejected — unnecessary churn on already-correct content,
  risks drift between two descriptions of the same topology).

## Freshness / point-in-time marker

- **Decision**: A single line near the top of `docs/pattern/README.md`:
  "Reflects commit `<short-sha>` (`<date>`)."
- **Rationale**: Cheap, greppable, matches common convention for
  point-in-time technical documentation; satisfies FR-010 without any
  tooling/automation.
- **Alternatives considered**: An automated regenerate-on-commit mechanism
  (rejected — disproportionate for a single-maintainer playground repo per
  the Constitution's Development Workflow section, which already accepts
  "no CI configured yet").

## Validation approach (no automated doc tests)

- **Decision**: `quickstart.md` scripts the acceptance scenarios from
  spec.md as literal review steps (e.g. "give a cold reader only
  `docs/pattern/`, time how long until they can redraw the chart hierarchy")
  rather than any automated prose-linting/testing tool.
- **Rationale**: The spec's own Success Criteria are reader-comprehension
  and reproduction-time based (SC-001–SC-004), which aren't mechanically
  testable; a scripted manual walkthrough is the standard way to validate
  documentation quality against stated goals.
- **Alternatives considered**: A markdown linter / link-checker CI step
  (worth adding later, per the Constitution's "adding CI ... is welcome but
  not yet required," but out of scope for this feature — it would validate
  syntax, not whether the content actually satisfies SC-001–SC-004).

## Structured content schemas (feeds Phase 1 contracts)

- **Decision**: `pitfalls.md` and `applicability-guide.md` entries each
  follow a fixed schema (see `contracts/`) rather than free-form prose, so
  authoring tasks have a concrete "fill this in" shape and future entries
  stay consistent.
- **Rationale**: Both are meant to be scanned/compared quickly (spec's
  Acceptance Scenarios describe classifying/checking against them), which
  free-form paragraphs make harder than a consistent field-by-field entry.
- **Alternatives considered**: Free-form narrative sections (rejected —
  harder to guarantee SC-003's "100% of pitfalls appear" is actually
  checkable, and harder for an AI assistant to reliably extract structured
  judgments per FR-007).
