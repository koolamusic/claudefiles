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

## Untrack committed state

1. **Skip if empty.** If `TRACKED_STATE` (from Preflight step 3) is empty, print "No tracked workflow state detected — migrate is equivalent to setup for this project" and jump straight to "## Setup (shared with /studio:setup)".

2. **For each path in `TRACKED_STATE`** (in the order `[.jira, .planning, .retrospective, .uat]`), decide dir-vs-file and untrack:
   - Probe: if the working-tree path exists as a directory (`test -d "$path"`) OR `git ls-files --cached -- "$path/" 2>/dev/null` returns any entries below the path, treat it as a directory and use the recursive form:
     ```bash
     git rm --cached -r "$path"
     ```
   - Otherwise (single tracked file, no entries below it), use the non-recursive form:
     ```bash
     git rm --cached "$path"
     ```
   - Capture the exit status. Do NOT `|| true` or otherwise swallow errors — on any non-zero exit, abort and surface the full git stdout and stderr to the user verbatim.
   - On success, print exactly one status line: `untracked <path> from index (files remain on disk)`.

3. **Do NOT commit.** **migrate leaves the `git rm --cached` deletions STAGED but UNCOMMITTED.** The user reviews `git status`, then commits manually with a message like `chore: untrack local workflow state (studio-managed)`. **migrate MUST NEVER run `git commit` in the project repo.** This is a hard prohibition — the rest of the file MUST NOT introduce a project-repo commit either.

4. **History preservation note.** **This step removes files from the git INDEX only. Prior history still contains them; `git log -- <path>` will show past commits that touched the path. This is intentional — history is never rewritten by this command.** If a user needs to purge prior history (for legal or secrets reasons), that is out of scope for studio; see "## Notes" at the bottom of this file.

## Setup (shared with /studio:setup)

Apply steps 3–N of `/studio:setup` (see `plugins/studio/commands/setup.md`) — do NOT duplicate that logic here. The following list enumerates each shared step by name and specifies the idempotence gate migrate adds on top. When a gate short-circuits, skip the entire step and move to the next one.

- **Create workspace dir `~/.studio/<slug>/`** — skip if it already exists and contains the expected subdirs (the `target_name` set from `studio.yaml` `symlinks` plus every entry in `workspace_dirs`); otherwise `mkdir -p` the missing ones.
- **Create symlinks at project root** — skip entirely if `SKIP_SYMLINK_CREATION=true` (set in Preflight step 5 when a matching `.workspacerc` was already present); otherwise apply the same move-then-symlink logic documented in `/studio:setup`'s "Move existing project state" and "Write symlinks" steps. Per-link: skip when the link already points into `~/.studio/$SLUG/$target_name`.
- **Sync managed `.gitignore` block** — ALWAYS run. Use the same marker-aware replace-between-markers logic as `/studio:setup` (read markers from `studio.yaml`, do NOT redefine them here). When the block is already present and content-equal, the replacement is a byte-for-byte no-op.
- **Copy session-start hook into `~/.studio/<slug>/hooks/`** — skip if the destination already exists and its checksum matches the plugin's canonical `${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh`; otherwise copy fresh and `chmod +x`.
- **Wire the hook into `.claude/settings.json`** — skip per-entry if an entry with the same resolved `command` string already exists in `settings.hooks.SessionStart`; otherwise APPEND (never replace — the user's other hooks remain untouched).
- **Write `.workspacerc`** — skip if it already exists and its content matches the expected `{"version": 1, "workspace": "~/.studio/<slug>"}` breadcrumb; otherwise write with 2-space indent and a trailing newline.

Do NOT run `/studio:setup`'s "Commit in the project repo" step. Migrate leaves all project-repo changes staged for the user to review (see "## Untrack committed state" step 3). Migrate MAY run `/studio:setup`'s "Commit in the `~/.studio` repo" step — the studio repo is owned by the command, not by the user's project.

## Post-migration summary

Print a concise report covering:

- **Untracked paths** — the `TRACKED_STATE` set from "## Untrack committed state" step 2, or "(none)".
- **Symlinks** — list each link name and whether it was `created`, `already-correct`, or `skipped (SKIP_SYMLINK_CREATION)`.
- **Gitignore block** — one of `created`, `re-synced (block replaced)`, or `unchanged`.
- **Session hook** — one of `installed`, `updated`, or `unchanged`; and one of `wired in settings.json`, `already wired`.
- **`.workspacerc`** — one of `written`, or `already matched`.
- **Next-step commands** for the user, verbatim:
  ```bash
  git status
  git commit -m "chore: untrack local workflow state (studio-managed)"
  ```
  (The second line is suggested, not mandatory — the user picks a message.) Migrate itself ran no project-repo commit.

## Idempotence contract

- Running `/studio:migrate` twice on the same project is a safe no-op on the second run.
- Every mutating step is preceded by a state check that can short-circuit — no step assumes its own prior non-execution.
- The command never assumes clean state: every precondition (tracked entries, staged diffs, existing `.workspacerc`, existing symlinks, existing gitignore block, existing hook entry) is re-verified at run time.
- `TRACKED_STATE` may be empty on the second run (step 1 of "## Untrack committed state" short-circuits); the shared setup section still runs and each of its gates short-circuits in turn.
- No step in this command ever rewrites git history — re-running remains history-preserving as well.

## Notes

- For greenfield projects (no tracked state, no `.workspacerc`), prefer `/studio:setup`. `/studio:migrate` will still work but does extra preflight checks that aren't needed.
- History is NEVER rewritten by this command. If you need to purge `.retrospective/` (or any other path) from prior commits (for legal or secrets reasons), use a dedicated history-rewriting tool separately — that is out of scope for `/studio:migrate` and out of scope for studio overall.
- The managed `.gitignore` markers are defined in `studio.yaml` and consumed by `/studio:setup`. Migrate references them by name and does not redefine them; if you need to change the markers, change them in `studio.yaml` and re-run migrate (or `/studio:sync`).
