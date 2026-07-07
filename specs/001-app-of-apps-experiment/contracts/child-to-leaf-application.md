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
