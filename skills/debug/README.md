# Why this skill exists

The default failure mode under a bug is guess-and-check: propose a plausible
fix, run it, propose another. It feels fast and it isn't — fixes stack on
unverified hypotheses, each one masking the symptom a little differently. This
skill enforces the discipline that actually is fast: root cause before any fix,
one hypothesis at a time, and a hard stop at three failed fixes (at which point
the problem is architectural, not a missing patch).

The most useful parts in practice: the boundary-instrumentation recipe for
multi-component failures (log what enters and exits each layer, *then* point
fingers) and the backward-tracing rule — never stop at "this line crashed",
keep going until you know which caller produced the bad value.

## Provenance

Copied from `.reference/skills/debug` with only phrasing adapted ("your human
partner" → "the user"). The framework itself is tool-agnostic and needed no
porting.

## Relation to other skills

`tdd` covers writing the regression test once the root cause is known (Phase 4
here hands off to it for complex business logic). The jira plugin's executor
debug loop is narrower — per-criterion test triage — and unrelated.
