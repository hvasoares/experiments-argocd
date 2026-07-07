# Data Model: Reproducible & Applicability-Ready Repo Documentation

This feature's "entities" are documentation artifacts, not application data.
This document maps each Key Entity from spec.md to its concrete file and the
content it must contain, so `tasks.md` can generate one authoring task per
file with an unambiguous definition of done.

## Documentation Set

The whole collection produced by this feature.

| Field | Value |
|---|---|
| Location | `docs/pattern/` |
| Members | `README.md`, `architecture.md`, `library-reuse-pattern.md`, `reproduction-guide.md`, `pitfalls.md`, `applicability-guide.md` |
| Entry point | `README.md` (User Story 3) |
| External links required | Root `README.md` → `docs/pattern/README.md`; `docs/pattern/README.md` → every other member file AND `specs/001-app-of-apps-experiment/{plan.md,data-model.md,contracts/,quickstart.md,research.md}` |
| Freshness marker | One line in `README.md`: "Reflects commit `<short-sha>` (`<date>`)" (FR-010) |

## Architecture Overview (`docs/pattern/architecture.md`)

| Field | Requirement source | Must contain |
|---|---|---|
| Chart hierarchy diagram | FR-001 | Parent → platform-addons/team-addons → leaf Application → upstream dependency, redrawable from memory |
| Value-flow mechanics | FR-002 | Named mechanism at each hand-off: `chart.mergedValues` (Sprig `mergeOverwrite`) parent→child; Argo CD `valuesObject`/`valueFiles` child→leaf |
| Pinned dependency index | FR-004 | List of all upstream charts used (ingress-nginx, bitnami/postgresql, community-charts/outline) + a link to `docs/PREREQUISITES.md`'s "Pinned Chart Versions" section (not a duplicated version table) |
| Terminology definitions | FR-009 | "app-of-apps," "leaf Application," "tier" defined at first use |

## Library Reuse Pattern (`docs/pattern/library-reuse-pattern.md`)

| Field | Requirement source | Must contain |
|---|---|---|
| Concrete walkthrough | FR-003 | The actual `postgresql-team` example: Argo CD `spec.sources` (multi-source), `path` pointing at `platform-addons/default-add-ons/postgresql`, the `$values` ref source, `team-addons/overlays/postgresql/values.yaml`'s one override, and where tenant-identity fields (`auth.database`, `auth.postgresPassword`) live instead |
| Named files | FR-003 | Exact repo paths, not paraphrased descriptions |
| Terminology | FR-009 | "multi-source values reuse" defined at first use |

## Reproduction Guide (`docs/pattern/reproduction-guide.md`)

| Field | Requirement source | Must contain |
|---|---|---|
| Bootstrap sequence | FR-005 | Ordered steps: tooling install → upstream Helm repo registration → parent chart skeleton → shared helpers → tier charts → wrapper/leaf charts → local cluster → root Application apply → sync verification |
| New-project framing | FR-005 | Written as "create this in an empty repo," not "this repo already has it" |

## Pitfalls Register (`docs/pattern/pitfalls.md`)

| Field | Requirement source | Must contain |
|---|---|---|
| Coverage | FR-006, SC-003 | 100% of distinct issues in `tasks.md`'s rollout notes / resolution log |
| Entry schema | `contracts/pitfall-entry-schema.md` | Symptom, root cause, fix, where-fixed-in-repo, per entry |

Known entries to migrate from `tasks.md` (non-exhaustive source list, final
authoring pass must reconcile against the actual file at write time):

1. Placeholder `repoURL` not pointing at a real, reachable git remote.
2. Leaf Application `path` needing to be repo-root-relative, not
   chart-relative (the `add-on-path` helper prefix bug).
3. Missing `syncOptions: [CreateNamespace=true]` on every leaf Application.
4. Bitnami/community subchart auto-generated passwords regenerating on
   every Helm render, rewriting live Secrets out from under initialized
   data volumes.
5. Outline's canonical `url` needing to match the actual access
   scheme/host exactly (no port allowed per the chart's `values.schema.json`).
6. Inline Argo CD override values needing to nest under the subchart's own
   key (e.g. `postgresql:`), or Helm silently ignores them.

## Applicability Assessment Guide (`docs/pattern/applicability-guide.md`)

| Field | Requirement source | Must contain |
|---|---|---|
| Fit signals | FR-007 | Existing GitOps tool in use; multi-tenant/multi-team structure; monorepo acceptability; existing Helm chart maturity — each with the tradeoff/adaptation it implies |
| Entry schema | `contracts/applicability-fit-signal-schema.md` | Signal, question to ask, per-answer verdict (applies as-is / applies with adaptation / does not apply), one-line rationale |
| Tool-agnostic framing | Edge Cases (Flux/Kustomize) | Explicitly separates Argo-CD-specific fit signals from pattern-general ones |

## Relationships

- `README.md` is the only file every other file is reachable from; no other
  file is required to link to more than its immediate neighbors plus back
  to `README.md`.
- `architecture.md` and `library-reuse-pattern.md` together satisfy User
  Story 1's "what is the pattern" half; `reproduction-guide.md` satisfies
  its "how do I build it" half.
- `pitfalls.md` is referenced by both `reproduction-guide.md` (avoid
  repeating these while building) and `applicability-guide.md` (check
  whether a target project already avoids them) — written once, linked
  twice, never duplicated.
