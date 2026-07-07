# Contract: Child App-of-Apps Chart → Leaf Application

Defines what each `templates/addons/*.yaml` template in `platform-addons/` or
`team-addons/` MUST produce for a single leaf Argo CD `Application`, and the
values contract each `default-add-ons/*` wrapper chart MUST accept in return.

## Producer: `{platform,team}-addons/templates/addons/<addon>.yaml`

Rendered only when `.Values.customAddons.<tier>.<addon>.enable` is `true`
(see data-model.md § Add-on Toggle). Required fields on the emitted
`Application`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <addon-name>            # e.g. postgresql-team, outline
  namespace: argocd
spec:
  destination:
    namespace: <customAddons.<tier>.<addon>.namespace>
  source:
    repoURL: <this repo>
    path: <customAddons.<tier>.<addon>.chartPath>   # default-add-ons/<addon>
    helm:
      values: <customAddons.<tier>.<addon>.values>  # inline YAML block
  syncPolicy:
    automated: {}
```

## Consumer requirement: `default-add-ons/<addon>/values.yaml`

Every key set under `customAddons.<tier>.<addon>.values` MUST correspond to a
real key in the wrapper chart's own `values.yaml` schema (which is itself
constrained by the upstream chart's schema, e.g. `bitnami/postgresql`'s
`auth.*`/`metrics.*` keys). The wrapper chart MUST NOT silently swallow an
unrecognized override — `helm lint`/`helm template` catching a typo'd key
here is exactly what Constitution Principle II exists to guarantee.

## Isolation contract (platform vs. team)

For any addon type that exists in both tiers (currently `postgresql`), the
two tiers' `values` blocks MUST differ in at least `namespace` and any
credential/secret-name field, and MUST NOT reference each other's Service
name. `team-addons`' `outline` leaf Application's database connection value
MUST resolve to `postgresql-team.<team-namespace>.svc.cluster.local`, never
the platform equivalent (spec FR-005, Edge Cases).

## Variant producer: reuse-as-a-library via Argo CD multi-source

`postgresql-team` (`team-addons/templates/addons/postgresql.yaml`) does NOT
follow the single-`source` shape above — it has no `default-add-ons/postgresql`
wrapper chart of its own. Instead it reuses
`platform-addons/default-add-ons/postgresql` directly as its chart, via Argo
CD's multi-source (`spec.sources`, plural) feature, to minimize drift between
the two tiers to exactly one deliberate value:

```yaml
spec:
  sources:
    - repoURL: <this repo>
      path: platform-addons/default-add-ons/postgresql   # platform's chart, reused
      helm:
        valueFiles:
          - $values/team-addons/overlays/postgresql/values.yaml  # the one override
        values: <customAddons.team.postgresql.values>             # tenant-identity fields
    - repoURL: <this repo>
      ref: values   # no chart rendered; just lends its tree for the $values alias above
```

This makes three things explicit and separately reviewable:

1. **Shared base** — platform's chart directory, `Chart.yaml` (dependency pin),
   and `values.yaml` are the single source of truth; team's Application never
   copies them.
2. **The one demonstrated override** — `team-addons/overlays/postgresql/values.yaml`
   contains exactly one key (`postgresql.metrics.enabled: true`) and nothing
   else, so "what team changed vs. platform" is a one-line diff, not a
   re-read of a whole duplicated values file.
3. **Tenant-identity fields** (`auth.database`, `auth.postgresPassword`) are
   necessarily different per tenant regardless of any drift-minimization
   goal (Outline requires its own database/credentials) — these ride the
   pre-existing `customAddons.team.postgresql.values` inline-override
   mechanism instead of the overlay file, so the overlay file's "one
   override" claim stays literally true.

Any future addon that wants this same "reuse platform's chart, override N
values" shape should follow the same three-part split rather than growing
the overlay file into a second copy of platform's values.
