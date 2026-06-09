# <CODE>: <one-line failure summary>

> Written by `/warden:triage`. One file per failing assertion. Filename:
> `<NN>-<slug>.md` under `.warden/remediation/`.

**Plan**: `<phase>/<plan-name>.md` step `<step or assertion id>`
**First seen**: `<YYYY-MM-DD>` (run `<RUN_ID>`)
**Last seen**: `<YYYY-MM-DD>` (run `<RUN_ID>`)
**Priority**: P0 (blocker) | P1 (must fix this iteration) | P2 (next iteration) | P3 (chore)
**Category**: assertion | setup | flake | env | regression

## Symptom

What the test saw. The exact failing assertion id and detail, plus any
relevant output captured from the log. Quote verbatim where possible.

```
WARDEN_RESULT fail <id> <detail>
```

## Reproduction

How to reproduce in isolation, ideally a one-liner:

```bash
bash .warden/run.sh <plan-name>
```

Or, if the failure requires specific state, the minimal seeding:

```bash
# Seed precondition
psql "$DATABASE_URL" -c "..."
# Re-run targeted plan
bash .warden/run.sh <plan-name>
```

## Root cause

What's actually broken. Cite specific files and line numbers from the
codebase under test, not from the plan. Use `<path>:<line>` style.

1. `<path>:<line>`: what's wrong here
2. `<path>:<line>`: what's wrong here

## Cascading impact

Other plans this blocks (if any). Empty if the failure is contained.

- `<other-plan>.md` step `<id>`: cascading symptom

## Suggested fix

Concrete change. Code snippets if useful, but lean on file:line
references rather than reproducing the whole function.

## Notes

Anything that adds context: linked issues, prior remediation attempts,
PO/stakeholder reports, decisions deferred.
