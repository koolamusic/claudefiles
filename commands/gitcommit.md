---
name: gcw
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*)
description: Create a git commit with conventional commit format
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Full diff: !`git diff HEAD`
- Recent commits: !`git log --oneline -5`

## Your task

1. Check if there are changes to commit; if none, inform the user and stop
2. Review the diff for sensitive data (API keys, passwords, .env files) — warn if found
3. Analyze changes to understand the nature and purpose
4. Generate 3 commit message candidates per the **Message format** section below
5. Present candidates to the user and ask which to use (or suggest edits)
6. Stage unstaged changes if user confirms
7. Execute `git commit` with the selected message
8. If pre-commit hooks fail, report the error and offer to fix

## Message format

Conventional Commits. Why over what — the diff already shows what changed. Match project convention (use the recent-commits context above to detect capitalization, scope style, and trailer usage).

### Subject line

- Format: `<type>(<scope>): <imperative summary>` — scope optional
- Append `!` after type/scope to mark a breaking change: `feat(api)!:` or `feat!:`
- Imperative mood: "add", "fix", "remove" — not "added", "adds", "adding"
- ≤50 chars when possible, hard cap 72
- No trailing period

### Types

- `feat` — new feature
- `fix` — bug fix
- `refactor` — code restructuring without behavior change
- `perf` — performance improvement
- `docs` — documentation
- `test` — tests
- `chore` — maintenance, tooling, deps
- `build` — build system, packaging
- `ci` — CI configuration
- `style` — formatting, whitespace
- `revert` — reverts a prior commit

### Body

- Skip when the subject is self-explanatory
- Add when the *why* isn't obvious from the diff
- Wrap at 72 chars; bullets `-` not `*`
- Reference issues/PRs at end as trailers: `Closes #42`, `Refs #17`

**Mandatory body** (regardless of how obvious it seems): breaking changes, security fixes, data migrations, reverts.

### Never include

- "This commit does X", "I", "we", "now", "currently" — the diff says what
- "As requested by..." — use a `Co-authored-by:` trailer instead
- Any AI attribution ("Generated with Claude Code", co-authorship footer, etc.)
- Emoji unless project convention requires
- Restating the filename when scope already says it

### Examples

New endpoint with body explaining the why:

Bad: `feat: add a new endpoint to get user profile information from the database`

Good:
```
feat(api): add GET /users/:id/profile

Mobile client needs profile data without the full user payload
to reduce LTE bandwidth on cold-launch screens.

Closes #128
```

Breaking API change:

```
feat(api)!: rename /v1/orders to /v1/checkout

BREAKING CHANGE: clients on /v1/orders must migrate to /v1/checkout
before 2026-06-01. Old route returns 410 after that date.
```

## Constraints

- DO NOT add Claude co-authorship footer
- DO NOT commit files containing secrets without explicit user confirmation
- DO NOT use `git commit --amend` unless explicitly requested
