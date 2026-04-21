---
description: Migrate a legacy project into a studio workspace — untracks committed state, then performs standard setup.
allowed-tools: Bash(git:*), Bash(ls:*), Bash(mkdir:*), Bash(mv:*), Bash(ln:*), Bash(test:*), Bash(cat:*), Read, Write, Edit
argument-hint: "[--slug <name>]"
---

# /studio:migrate

For legacy projects that pre-exist with scattered workflow state AND may have that state committed to git. Untracks tracked state via `git rm --cached -r` (preserves history — does NOT rewrite it), then delegates to the same setup steps as `/studio:setup`. Safe to run more than once.

## Preflight

This section is READ-ONLY. No filesystem or git index mutations occur here. Every branch decision that affects later sections is recorded as a named flag or set (`PROJECT_ROOT`, `SLUG`, `TRACKED_STATE`, `SKIP_SYMLINK_CREATION`).

1. **Verify project context.** Run `git rev-parse --show-toplevel`. If it fails (not inside a git repo), stop with: "Not a git repository — run `git init` first. Studio workspaces are keyed to a git repo's basename." On success, record the stdout as `PROJECT_ROOT` and use it for every subsequent path.

2. **Derive slug.** Same algorithm as `/studio:setup`:
   - If the command was invoked with `--slug <name>`, use that literal.
   - Else `SLUG=$(basename "$PROJECT_ROOT")`.
   - If `~/.studio/$SLUG/` already exists AND contains a `.setup-owner` marker that names a DIFFERENT project, offer a collision suffix (`$SLUG-2`, then `$SLUG-3`, ...) via `AskUserQuestion`. Do not auto-overwrite.

3. **Detect tracked state.** For each path in the literal list `[.jira, .planning, .retrospective, .uat]`, run:
   ```bash
   git ls-files --cached --error-unmatch -- "$path" 2>/dev/null
   ```
   If the command exits 0, the path has at least one entry in the git index. Record the set of such paths as `TRACKED_STATE`. If `TRACKED_STATE` is empty, migrate becomes equivalent to `/studio:setup` (that is handled in step 1 of "## Untrack committed state").

4. **Check for conflicting staged changes.** For each path in `TRACKED_STATE`, run:
   ```bash
   git diff --cached --name-only -- "$path"
   ```
   If the output is non-empty (the user has staged additions / modifications / deletions inside a path we are about to touch), abort with the exact message: "Uncommitted staged changes in `<path>`. Commit or stash them before running `/studio:migrate`, otherwise the upcoming untrack step would conflict with your staged work." Surface the prompt via `AskUserQuestion` so the user can choose to cancel, stash, or commit before continuing. Do NOT auto-resolve.

5. **Check for pre-existing `.workspacerc`.** If `$PROJECT_ROOT/.workspacerc` exists, read it and parse its `workspace` field.
   - If the parsed workspace path resolves to `~/.studio/$SLUG` (the slug derived in step 2), emit: "Re-running migrate on already-migrated project — will sync gitignore and skip symlink creation" and set `SKIP_SYMLINK_CREATION=true` for use in "## Setup (shared)".
   - If the parsed workspace path points to a DIFFERENT slug, abort with a message describing the mismatch and ask the user whether to adopt the existing slug (re-run with `--slug <existing>`) or cancel.
   - If `.workspacerc` is absent, leave `SKIP_SYMLINK_CREATION` unset (defaults to false).

6. **Summarise findings.** Print a concise pre-flight report to the user listing:
   - `PROJECT_ROOT` and `SLUG`.
   - `TRACKED_STATE` — the set of paths with tracked entries, or "(none)".
   - For each of `.jira`, `.planning`, `.retrospective`, `.uat`: whether the path exists on disk as (a) a real directory, (b) a symlink (and where it points), or (c) absent.
   - Symlink status at project root (which of the four link names already exist, and whether they already point into `~/.studio/$SLUG/`).
   - `SKIP_SYMLINK_CREATION` flag value.
   This is still READ-ONLY. Ask for confirmation before proceeding to any mutating section.
