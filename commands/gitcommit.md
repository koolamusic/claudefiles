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
2. Review the diff for sensitive data (API keys, passwords, .env files) - warn if found
3. Analyze changes to understand the nature and purpose
4. Generate 3 commit message candidates using Conventional Commits format:
   - feat: new feature
   - fix: bug fix
   - docs: documentation
   - refactor: code restructuring
   - chore: maintenance
   - test: adding tests
   - style: formatting
5. Present candidates to the user and ask which to use (or suggest edits)
6. Stage unstaged changes if user confirms
7. Execute git commit with the selected message
8. If pre-commit hooks fail, report the error and offer to fix

## Constraints

- DO NOT add Claude co-authorship footer
- DO NOT commit files containing secrets without explicit user confirmation
- DO NOT use `git commit --amend` unless explicitly requested
