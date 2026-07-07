<!--
AI-AGENT NOTE (Cursor/Claude/etc.): this is the entry point for this whole
doc set. If you're a fresh agent session with no other context, start here,
figure out which of the two goals below matches what you're being asked to
do, and follow that link — don't read every file in this directory
front-to-back unless asked to.
-->

# Argo CD app-of-apps pattern — documentation

Reflects commit `537e8d0` (2026-07-07). This is a point-in-time snapshot,
not live-generated — if this repo's structure has changed since, treat this
as a starting reference rather than ground truth (see spec.md's Edge Cases
for why).

This repo is a playground demonstrating a GitOps **app-of-apps** pattern:
a parent Helm chart renders per-tier child charts (platform-owned,
team-owned), which render leaf Argo CD Applications wrapping pinned
upstream charts — with one tier reusing another tier's chart as a library
where their configs are nearly identical.

## Two things you can do with this doc set

**Reproduce this pattern in a new project** — you have an empty repo and
want to build the same thing:
1. [`architecture.md`](./architecture.md) — the shape of the system
2. [`library-reuse-pattern.md`](./library-reuse-pattern.md) — the one
   trick worth copying exactly
3. [`reproduction-guide.md`](./reproduction-guide.md) — ordered steps

**Assess whether this pattern applies to an existing project** — someone
said "check this repo out, can we apply this to our project?":
1. [`applicability-guide.md`](./applicability-guide.md) — fit signals,
   dimension by dimension
2. [`pitfalls.md`](./pitfalls.md) — real bugs hit building this, check
   whether the target project already avoids them

## Where the deeper detail lives

This doc set intentionally does not duplicate the fine-grained design
artifacts already produced for this pattern — it links to them instead:

| Question | Where to look |
|---|---|
| Exact values contract, field by field | [`../../specs/001-app-of-apps-experiment/contracts/`](../../specs/001-app-of-apps-experiment/contracts/) |
| Entity/data shapes (Registered App, Add-on Toggle, etc.) | [`../../specs/001-app-of-apps-experiment/data-model.md`](../../specs/001-app-of-apps-experiment/data-model.md) |
| Why decisions were made a certain way | [`../../specs/001-app-of-apps-experiment/research.md`](../../specs/001-app-of-apps-experiment/research.md) |
| Full implementation plan | [`../../specs/001-app-of-apps-experiment/plan.md`](../../specs/001-app-of-apps-experiment/plan.md) |
| Runnable validation steps | [`../../specs/001-app-of-apps-experiment/quickstart.md`](../../specs/001-app-of-apps-experiment/quickstart.md) |
| Every real bug hit + fix, blow-by-blow | [`../../specs/001-app-of-apps-experiment/tasks.md`](../../specs/001-app-of-apps-experiment/tasks.md)'s rollout notes (this doc set's [`pitfalls.md`](./pitfalls.md) is the curated, reader-facing version) |

## Per-directory context

Each project directory in this repo also has its own scoped `CLAUDE.md` —
see the [root `CLAUDE.md`](../../CLAUDE.md)'s project index table.
