---
sprint: {{sprint_slug}}
verified_at: {{iso_timestamp}}
verdict: PASS | FAIL | PARTIAL
---

# Verification: {{sprint_slug}}

Goal-backward audit of the executed sprint. Asks: "does the codebase, as it stands now, deliver what the goal promised?" — distinct from `jira-nyquist` (which asks "do tests cover the criteria?") and `jira-reviewer` (which audits the diff).

## Goal

{{goal_from_plan_frontmatter}}

## Goal decomposition

The goal implies these observable outcomes. The verifier walks each one and reports.

- [ ] {{outcome_1}}
- [ ] {{outcome_2}}

## Findings

For each outcome, typed evidence. Types: `command` (exact command + output), `source-audit` (`path:line` or search query), `browser` (route + observation), `artifact` (generated file path), `external-source` (URL/issue), `N/A: <reason>`.

### {{outcome_1}}

- **Status:** delivered | partial | missing
- **Evidence:** `<type>` — `path:line` or command output proving it
- **Gap:** if partial/missing, what specifically is absent

## Source coverage

Cross-check against CONTEXT.md decisions:

| Decision | Plan | Implemented | Evidence |
|----------|------|-------------|----------|
| D-01     | 01-PLAN.md task II | yes | source-audit: `src/foo.ts:42` |

## Verdict

**PASS** — all outcomes delivered, all locked decisions implemented.
**PARTIAL** — some outcomes delivered; gaps listed above.
**FAIL** — goal not achieved; route back to executor or plan another sprint.

## Next steps

If PARTIAL or FAIL: specific list of follow-up tasks (don't write them as plans here; the orchestrator decides whether to extend the sprint or open a new one).
