# Contract: Pitfall Register Entry Schema

Defines the fixed shape every entry in `docs/pattern/pitfalls.md` MUST
follow, so coverage (SC-003: 100% of distinct issues from `tasks.md`'s
rollout notes) is mechanically checkable and a reader can scan entries
without parsing prose.

## Fields (per entry)

```markdown
### <short title>

- **Symptom**: <what the reader would actually observe — an error message,
  a crash-loop, a stuck sync status>
- **Root cause**: <the actual mechanism, one or two sentences>
- **Fix**: <what changed, named concretely — a file, a key, a value>
- **Where fixed in this repo**: <repo-relative path(s)>
```

## Example (from this repo's own history)

```markdown
### Bundled/subchart passwords regenerate on every Helm render

- **Symptom**: A previously-working Postgres or Redis instance suddenly
  fails with "password authentication failed" or "WRONGPASS," with no
  intentional credential change.
- **Root cause**: Bitnami (and similarly-built) charts generate a fresh
  random password on every `helm template` render when the password field
  is left empty. Argo CD re-renders on every sync, silently rewriting the
  live Secret out from under an already-initialized data volume that still
  expects the old value.
- **Fix**: Pin a fixed value for every such password field instead of
  leaving it empty.
- **Where fixed in this repo**: `platform-addons/default-add-ons/postgresql/values.yaml`,
  `team-addons/overlays/postgresql/values.yaml`,
  `team-addons/default-add-ons/outline/values.yaml` (`redis.auth.password`)
```

## Validation rule

Every entry MUST be traceable to a real occurrence recorded in `tasks.md`'s
rollout notes / resolution log — this register documents issues that
actually happened during this repo's own build, not hypothetical risks.
Hypothetical/anticipated issues belong in `docs/pattern/architecture.md` or
`reproduction-guide.md` as caveats, not in this register.
