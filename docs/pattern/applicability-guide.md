<!--
AI-AGENT NOTE (Cursor/Claude/etc.): This is the file to use when a user
says "check this repo out, can we apply this to our project?" Walk through
each fit signal against the target project's actual repo/stack and give a
verdict + one-line reason for each — don't just say yes/no for the whole
pattern. Entries follow ../../specs/002-repo-documentation/contracts/
applicability-fit-signal-schema.md.
-->

# Applicability assessment guide

Use this against **any** real-world project a reader brings — it is not a
diff against one fixed external repo. For each fit signal below, answer the
question against the target project and read off the verdict.

### Existing GitOps tool

- **Question to ask of the target project**: Is it already deployed and
  synced via Argo CD (any topology)?
- **If yes**: Applies with adaptation — the app-of-apps tiering and
  multi-source reuse mechanisms transfer directly; only the chart layout
  needs restructuring into tiers.
- **If no (Flux, plain Kustomize, or manual kubectl)**: Applies with
  adaptation — the *idea* (tiered ownership, drift-minimized reuse) is
  tool-agnostic and re-implementable, but the specific mechanism
  (`spec.sources`/`valueFiles`) does not transfer as-is.
- **Argo-CD-specific or pattern-general?**: Mechanism is Argo-CD-specific;
  the tiering/reuse idea is pattern-general.

### Multi-tenant / multi-team structure

- **Question to ask of the target project**: Do at least two teams or
  environments need similar-but-not-identical infrastructure (e.g. each
  gets its own database, but the shape is the same)?
- **If yes**: Applies as-is — this is exactly the scenario the
  platform/team tiering and library-reuse pattern were built for.
- **If no (single team, single environment)**: Does not apply — the whole
  point of tiering is managing drift between multiple similar-but-distinct
  consumers; with only one consumer there's nothing to minimize drift
  against.
- **Argo-CD-specific or pattern-general?**: Pattern-general.

### Monorepo acceptability

- **Question to ask of the target project**: Can all tiers' charts live as
  sibling directories in one repository, or is a hard multi-repo split
  required (e.g. for access-control reasons)?
- **If monorepo is acceptable**: Applies as-is — this repo's own reuse
  trick depends on multiple `Application` sources pointing at the same
  `repoURL`, different `path`s, which is simplest in one repo.
- **If multi-repo is required**: Applies with adaptation — Argo CD
  multi-source still works across different `repoURL`s per source, but
  cross-repo version/release coordination becomes a real operational
  concern this repo's single-repo setup never had to solve.
- **Argo-CD-specific or pattern-general?**: Pattern-general (the
  monorepo-vs-multirepo tradeoff exists regardless of GitOps tool).

### Existing Helm chart maturity

- **Question to ask of the target project**: Does the target already wrap
  its infrastructure in Helm charts (even simple ones), or is it raw
  manifests/Kustomize?
- **If Helm charts already exist**: Applies as-is — wrapping them as leaf
  Applications and adding a tiering layer on top is additive.
- **If no Helm charts exist yet**: Applies with adaptation — charts need to
  be authored first; the tiering/reuse pattern itself doesn't change, but
  there's meaningfully more upfront work before it can be exercised.
- **Argo-CD-specific or pattern-general?**: Pattern-general.

## Before concluding "doesn't apply" outright

Check [`pitfalls.md`](./pitfalls.md) against the target project's existing
setup first — if it already handles pinned-password idempotency,
repo-root-relative paths, and namespace creation correctly, that's often a
sign the target project is more ready for this pattern than a first read
suggests, even if today's chart layout looks nothing like this repo's.

## Next

- What the pattern actually looks like, in detail →
  [`architecture.md`](./architecture.md) and
  [`library-reuse-pattern.md`](./library-reuse-pattern.md)
- Real issues to check the target project already avoids →
  [`pitfalls.md`](./pitfalls.md)
