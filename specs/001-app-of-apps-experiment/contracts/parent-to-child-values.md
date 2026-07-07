# Contract: Parent Chart → Child App-of-Apps Chart

Defines the `spec.source.helm.valuesObject` payload the parent chart
(`chart/`) MUST produce for each child `Application` it renders, and what the
child chart (`platform-addons/` or `team-addons/`) MUST accept.

## Producer: `chart/templates/applications.yaml`

For each entry in `.Values.apps` (see data-model.md § Registered App), the
parent chart renders one Argo CD `Application` whose `spec.source.helm.valuesObject`
is the deep-merge (base → env → cluster, via the `chart.mergedValues` helper)
of:

1. Cluster Context Values (`clusterName`, `account`, `region`, `dns`, `environment`)
2. That app's own `values` override block

```yaml
# Illustrative shape of spec.source.helm.valuesObject passed to a child
clusterName: kind-argocd-playground
account: "000000000000"
region: local
dns: example.com
environment: local
# + any app-specific overrides from apps.<name>.values
```

## Consumer requirement: child app-of-apps charts

`platform-addons/` and `team-addons/` MUST declare these same top-level keys
in their own `values.yaml` as documented defaults (so `helm lint`/`helm
template` succeed standalone, per Constitution Principle II, without
requiring the parent chart to be rendered first). Each child chart's
`_helpers.tpl` MUST read `clusterName`/`dns`/`environment` only through
these top-level keys — no child chart may invent its own alternate key name
for the same concept.

## Compatibility rule

Adding a new top-level Cluster Context field is backward compatible (children
that don't read it simply ignore it). Renaming or removing an existing field
is a breaking change and MUST be applied to the parent chart and every child
chart in the same commit, per Constitution Principle II's "broken values
contract at one layer silently breaks everything downstream."
