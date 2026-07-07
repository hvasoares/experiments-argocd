# Quickstart: Validate the Documentation Set

There's no automated test suite for prose — validation is a structured
manual review against spec.md's Success Criteria. Run these scenarios after
`docs/pattern/*.md` are written, before considering this feature done.

## Prerequisites

- `docs/pattern/README.md`, `architecture.md`, `library-reuse-pattern.md`,
  `reproduction-guide.md`, `pitfalls.md`, `applicability-guide.md` all exist
- A reviewer (can be a fresh Claude/Cursor session with no other context
  from this repo, or a human colleague) willing to follow the scenarios below

## 1. Chart hierarchy comprehension (SC-001)

Give the reviewer only `docs/pattern/architecture.md`. Ask: "Describe the
full chart hierarchy and one complete parent-to-leaf value flow."

**Expected outcome**: Correct answer, citing only the document, within 5
minutes — parent → platform-addons/team-addons → leaf Application → upstream
dependency, with the `chart.mergedValues`/`valuesObject` mechanism named.

## 2. Library reuse pattern reproducibility (spec US1, Acceptance Scenario 2)

Give the reviewer only `docs/pattern/library-reuse-pattern.md`. Ask: "Show
me exactly which files I'd create/edit to make one tier's chart reused by
another, overriding exactly one value."

**Expected outcome**: A concrete, copyable answer naming the real Argo CD
`spec.sources` shape and the specific files involved — not an abstract
description of "you could use multi-source."

## 3. Reproduction skeleton (SC-002)

Give the reviewer only `docs/pattern/reproduction-guide.md`. Ask: "List, in
order, what you'd create in a brand-new empty repo to reach a working
parent → tier → leaf topology."

**Expected outcome**: An ordered list matching the actual bootstrap sequence
(tooling → repos → parent chart → helpers → tiers → leaves → cluster →
root Application → sync), produced within 15 minutes.

## 4. Pitfalls coverage (SC-003)

Diff `docs/pattern/pitfalls.md`'s entries against `tasks.md`'s rollout notes
/ resolution log.

**Expected outcome**: Every distinct issue recorded in `tasks.md` has a
corresponding entry (per `contracts/pitfall-entry-schema.md`); none are
missing.

## 5. Applicability judgment on an arbitrary project (SC-004)

Give the reviewer `docs/pattern/applicability-guide.md` plus any real or
hypothetical project description (not specified in advance — pick one on
the spot, e.g. "a Flux-based repo with one flat set of Kustomizations").
Ask: "For each fit signal, is this pattern applies-as-is,
applies-with-adaptation, or doesn't apply — and why?"

**Expected outcome**: A verdict + one-line rationale per fit signal, without
the reviewer asking a clarifying question about what to assess.

## 6. Entry-point navigation (spec US3)

Give the reviewer only `docs/pattern/README.md`. Ask: "Where's the values
contract for leaf Applications?"

**Expected outcome**: The reviewer is pointed at
`specs/001-app-of-apps-experiment/contracts/child-to-leaf-application.md`
— not a re-explanation of its contents.

## 7. Line-count / structure check

```bash
wc -l docs/pattern/*.md
```

**Expected outcome**: Every file ≤ 200 lines (Constitution Principle III).
