<!--
AI-AGENT NOTE (Cursor/Claude/etc.): This is the single most copy-pasteable
file in this doc set. If a user asks "how do I make one Helm chart reuse
another chart as a base and override just one value," the answer is
entirely in this file. Don't paraphrase it into the abstract — quote the
actual spec.sources shape below.
-->

# The "platform as a library" reuse pattern

## The problem it solves

`team-addons` needs its own PostgreSQL instance, nearly identical to
`platform-addons`' own Postgres — same chart, same version, same
architecture — except one value: `metrics.enabled`. The naive approach
(give `team-addons` its own copy of the wrapper chart) means two
`Chart.yaml` dependency pins to keep in sync by hand, and every future
tuning change made twice. This repo does not do that.

## The mechanism: Argo CD multi-source, not a Helm chart dependency

`team-addons` has **no** `default-add-ons/postgresql` directory of its own.
Its leaf Application (`team-addons/templates/addons/postgresql.yaml`)
renders an Argo CD `Application` with `spec.sources` (plural), not
`spec.source` (singular):

```yaml
spec:
  sources:
    # Source 1: the actual chart to render — platform's own chart, reused as-is.
    - repoURL: https://github.com/<org>/<repo>.git
      path: platform-addons/default-add-ons/postgresql
      targetRevision: HEAD
      helm:
        valueFiles:
          - $values/team-addons/overlays/postgresql/values.yaml   # the ONE override
        values: |                                                  # tenant-identity fields
          postgresql:
            auth:
              database: outline
              postgresPassword: outline-team-local-playground-pw
    # Source 2: no chart rendered here — it only lends its repo tree so
    # source 1's valueFiles can reference a file living outside
    # platform-addons/default-add-ons/postgresql (the $values alias above).
    - repoURL: https://github.com/<org>/<repo>.git
      targetRevision: HEAD
      ref: values
```

<!-- AI-AGENT NOTE: `ref: values` + `$values/<path>` is the exact Argo CD
feature name to search for if you need to look up how this works —
"Argo CD multi-source valueFiles $values reference." -->

## The three-way split that makes "one override" literally true

1. **Shared base** — `platform-addons/default-add-ons/postgresql`'s own
   `Chart.yaml` (the version pin) and `values.yaml` (architecture,
   persistence size, resources) are never copied, only referenced.
2. **The one demonstrated override** —
   `team-addons/overlays/postgresql/values.yaml` contains exactly one key:
   ```yaml
   postgresql:
     metrics:
       enabled: true
   ```
   Nothing else. This is what makes "team overrides one value" checkable —
   it's a one-line file, not a claim buried in a larger diff.
3. **Tenant-identity fields** (`auth.database`, `auth.postgresPassword`) —
   these legitimately differ per tenant (Outline needs its own database and
   credentials) but are **not** the demonstrated override. They ride the
   inline `spec.source.helm.values` shown above instead, kept out of the
   overlay file on purpose.

## Pitfall this pattern hit while being built

The inline `values:` block **must** nest under the reused chart's subchart
name (`postgresql:` here) — an un-nested `auth: ...` at the top level is
silently ignored by Helm and the base chart's own defaults leak through
instead. This is documented in full, with the exact symptom, in
[`pitfalls.md`](./pitfalls.md) — the entry titled "Inline override values
not nested under the subchart name."

<!-- AI-AGENT NOTE: if you reproduce this pattern and a value you're
overriding via spec.sources doesn't seem to take effect, check nesting
first — this exact mistake cost real debugging time in this repo (see
pitfalls.md) before the fix was found. -->

## When to reach for this vs. a normal wrapper chart

Use this pattern when: two tiers need the *same* upstream chart at the
*same* version, differing in only a small, named set of values. Don't use
it when: the two tiers' configs are mostly different (at that point a
regular per-tier wrapper chart, like `default-add-ons/outline` or
`default-add-ons/ingress-nginx`, is simpler and clearer than forcing a
reuse relationship that doesn't reflect reality.

## Next

- Full values contract for this pattern →
  [`../../specs/001-app-of-apps-experiment/contracts/child-to-leaf-application.md`](../../specs/001-app-of-apps-experiment/contracts/child-to-leaf-application.md)
  § Variant producer
- Building this from nothing → [`reproduction-guide.md`](./reproduction-guide.md)
