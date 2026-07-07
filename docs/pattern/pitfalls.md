<!--
AI-AGENT NOTE (Cursor/Claude/etc.): Every entry below is a REAL bug that
happened building this repo, not a hypothetical risk — see
specs/001-app-of-apps-experiment/tasks.md's rollout notes for the original,
messier account. If you're reproducing this pattern, grep this file before
you start debugging a sync failure; odds are decent it's already here.
-->

# Pitfalls encountered building this pattern

Each entry follows the schema in
[`../../specs/002-repo-documentation/contracts/pitfall-entry-schema.md`](../../specs/002-repo-documentation/contracts/pitfall-entry-schema.md).

### Placeholder repoURL not reachable

- **Symptom**: Argo CD `Application` stuck at `Sync Status: Unknown` with a
  `ComparisonError`: `failed to list refs: repository not found`, even
  though the manifest itself is valid.
- **Root cause**: `spec.source.repoURL` pointed at a placeholder
  (`https://example.com/...`) instead of a real git remote. Argo CD's
  repo-server runs in-cluster and cannot resolve a local filesystem path on
  your workstation — it needs a URL it can actually clone over the network.
- **Fix**: Push the repo to a real, reachable remote (GitHub/GitLab, public
  or private with credentials registered) and point `repoURL` there.
- **Where fixed in this repo**: `chart/values.yaml`, `bootstrap/root-application.yaml`, all four leaf Application templates.

### Leaf Application path not repo-root-relative

- **Symptom**: `ComparisonError: app path does not exist`, even though the
  directory clearly exists on disk.
- **Root cause**: Argo CD resolves `spec.source.path` from the **repo
  root**, not from the parent/tier chart's own directory. A helper that
  returns `default-add-ons/<name>` (missing its own tier-directory prefix)
  produces a path that doesn't exist from the repo root's perspective.
- **Fix**: Every path-building helper must return a full repo-relative
  path, e.g. `platform-addons/default-add-ons/<name>`, not
  `default-add-ons/<name>`.
- **Where fixed in this repo**: `platform-addons/templates/_helpers.tpl`'s `add-on-path` helper.

### Missing CreateNamespace=true on leaf Applications

- **Symptom**: Every sync attempt fails at the `PreSync` stage with
  `namespaces "<ns>" not found`.
- **Root cause**: The target namespace doesn't exist yet, and Argo CD
  doesn't create it automatically unless told to.
- **Fix**: Add `syncOptions: [CreateNamespace=true]` to every leaf
  Application's `syncPolicy`.
- **Where fixed in this repo**: all four leaf Application templates.

### Bundled/subchart passwords regenerate on every Helm render

- **Symptom**: A previously-working Postgres or Redis instance suddenly
  fails with "password authentication failed" or "WRONGPASS," with no
  intentional credential change.
- **Root cause**: Bitnami (and similarly-built) charts generate a fresh
  random password on every `helm template` render when the password field
  is left empty. Argo CD re-renders on its own reconcile cycle, silently
  rewriting the live Secret out from under an already-initialized data
  volume that still expects the old value.
- **Fix**: Pin a fixed value for every such password field instead of
  leaving it empty.
- **Where fixed in this repo**: `platform-addons/default-add-ons/postgresql/values.yaml`,
  `team-addons/overlays/postgresql/values.yaml`,
  `team-addons/default-add-ons/outline/values.yaml` (`redis.auth.password`).

### Canonical app URL must match the actual access scheme/host exactly

- **Symptom**: The app's HTML shell loads, then a client-side "Loading
  Failed" / network-error screen replaces it.
- **Root cause**: The app (Outline, in this repo) validates incoming
  request origins against its own configured canonical URL. If that URL
  was auto-derived (e.g. assumed `http://` with no port) and doesn't match
  how you're actually reaching it (e.g. `https://` via a non-standard
  port-forward port), API/websocket calls get rejected as an origin
  mismatch. Some charts' `values.schema.json` also outright forbid a port
  in this field, so the fix may require using the *standard* port for
  local access rather than adding one to the URL.
- **Fix**: Set the canonical URL explicitly to match reality; check the
  chart's schema for what's actually allowed before assuming a port works.
- **Where fixed in this repo**: `team-addons/default-add-ons/outline/values.yaml` (`outline.url`).

### Inline override values not nested under the subchart name

- **Symptom**: An override that should change a subchart's behavior (e.g.
  database name, password) appears to have no effect — the base chart's
  own default value is what actually gets used.
- **Root cause**: When one chart wraps another as a named dependency (a
  subchart), values meant for that dependency must be nested under the
  dependency's own name (e.g. `postgresql: { auth: { ... } }`). An
  un-nested top-level key (e.g. just `auth: { ... }`) lands nowhere Helm
  reads from — it's silently ignored, not an error.
- **Fix**: Always nest overrides under the subchart's declared name; verify
  with a manual `helm template <chart> --set <nested.key>=<value>` before
  wiring it through Argo CD.
- **Where fixed in this repo**: `team-addons/values.yaml`'s
  `customAddons.team.postgresql.values`.

## Next

- Assess whether a target project already avoids these →
  [`applicability-guide.md`](./applicability-guide.md)
- Avoid repeating these while building → [`reproduction-guide.md`](./reproduction-guide.md)
