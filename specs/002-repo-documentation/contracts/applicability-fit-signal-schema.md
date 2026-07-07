# Contract: Applicability Fit-Signal Schema

Defines the fixed shape every entry in `docs/pattern/applicability-guide.md`
MUST follow, so a reader (or an AI assistant such as Cursor) can produce the
per-dimension verdict spec.md's Acceptance Scenarios describe, without
inventing structure on the fly.

## Fields (per fit signal)

```markdown
### <fit signal name>

- **Question to ask of the target project**: <a single, concretely
  answerable question>
- **If yes / already true**: <verdict: applies as-is | applies with
  adaptation | does not apply> — <one-line rationale>
- **If no / not true**: <verdict> — <one-line rationale>
- **Argo-CD-specific or pattern-general?**: <one of the two — see Edge
  Cases in spec.md re: Flux/Kustomize targets>
```

## Example (from this repo's own pattern)

```markdown
### Existing GitOps tool

- **Question to ask of the target project**: Is it already deployed and
  synced via Argo CD (any topology)?
- **If yes**: Applies with adaptation — the app-of-apps tiering and
  multi-source reuse mechanisms transfer directly; only the chart layout
  needs restructuring.
- **If no (uses Flux, plain Kustomize, or manual kubectl)**: Applies with
  adaptation — the *idea* (tiered ownership, drift-minimized reuse) is
  tool-agnostic and re-implementable, but the specific mechanism (Argo CD
  `spec.sources`/`valueFiles`) does not transfer as-is.
- **Argo-CD-specific or pattern-general?**: Mechanism is Argo-CD-specific;
  the tiering/reuse idea itself is pattern-general.
```

## Validation rule

Every fit signal MUST resolve to one of exactly three verdicts (applies
as-is / applies with adaptation / does not apply) for at least one branch of
its question — a fit signal whose answer is always "does not apply"
regardless of the target project isn't a useful signal and should be
dropped rather than included for completeness' sake.
