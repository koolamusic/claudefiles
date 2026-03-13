# Nit Ignore

Triaged findings listed here are excluded from future Nit reports.

## How it works

Place this file at `.claude/nitignore.md` in your project root. Nit checks this file before reporting and skips any matching entries.

## Statuses

- **intentional** — Known behavior, won't fix. The code is correct by design.
- **remediated** — Bug was real and has been fixed.

## Entries

<!-- One entry per line. Nit matches on file + rule (category::description). -->
<!-- Lines and rationale are for humans — Nit keys on file + rule only. -->

| Status | Rule | File | Line(s) | Rationale |
|--------|------|------|---------|-----------|
<!-- | intentional | security::hardcoded-token | src/config.ts | 42 | Dev-only token, not used in production | -->
<!-- | remediated | error-handling::uncaught-promise | lib/api.js | 88 | Fixed in #234 | -->
