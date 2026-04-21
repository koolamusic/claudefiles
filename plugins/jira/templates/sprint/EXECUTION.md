# Execution: {{sprint_slug}}

Append-only log of what happened during `/jira:execute`. The executor writes here; humans read it.

## Started

{{iso_timestamp}}

## Branch / worktree

{{branch_or_none}}

## Task log

### I. {{task_title}}

- **Commit:** `{{sha}}`
- **Result:** done | deviated | blocked
- **Notes:** any deviation from PLAN.md and why

## Nyquist results

- [x] {{criterion}} — verified by `{{test_or_check}}`
- [ ] {{criterion}} — gap; `jira-nyquist` added `{{test_path}}`

## PR

{{pr_url_or_none}}

## Finished

{{iso_timestamp}}
