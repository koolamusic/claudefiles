---
description: Initialize the current project against ~/.studio/<slug>. Creates the workspace subdir, moves pre-existing .jira/.planning/.retrospective/.uat content into it, writes symlinks, syncs the managed .gitignore block (which also gitignores .workspacerc as a machine-local breadcrumb), writes .workspacerc at the project root. Idempotent. Reads studio.yaml for all configurable values.
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
argument-hint: (no arguments — slug derived from repo basename)
---

Initialize a studio workspace for the current project. All symlink pairs, workspace directory names, managed-gitignore markers and entries, and hook config come from `${CLAUDE_PLUGIN_ROOT}/templates/studio.yaml` — never hardcode these.

## Steps

1. **Locate config.** Read `${CLAUDE_PLUGIN_ROOT}/templates/studio.yaml`. Parse the following fields and use them by name in every subsequent step — do not bake any of these values into the command logic:
   - `symlinks` (map of `link_name` → `target_name`)
   - `workspace_dirs` (list of extra workspace-internal directories)
   - `gitignore.marker_start` (the start marker string)
   - `gitignore.marker_end` (the end marker string)
   - `gitignore.entries` (list of entries managed inside the block)
   - `hooks.SessionStart` (list of hook entries to wire)

   Every value below that looks like a literal (e.g. `.jira`, `# >>> studio (managed) >>>`) is only a running example showing what the parsed values will resolve to — the command's decision source is the parsed YAML, not inline literals.

2. **Verify git repo.** Run `git rev-parse --show-toplevel` to obtain `PROJECT_ROOT`. If the command fails (not inside a git repo), stop and tell the user to `git init` first — studio workspaces are keyed to a git repo's basename. Change working directory to `PROJECT_ROOT`.

3. **Derive slug.** `SLUG=$(basename "$PROJECT_ROOT")`. If `~/.studio/$SLUG` already exists, is non-empty, and does not contain a `.setup-owner` marker naming this project, use `AskUserQuestion` to offer: use `$SLUG` anyway, use `$SLUG-2` (or next free suffix), or cancel. Do not overwrite silently.

4. **Verify studio repo.** Confirm `~/.studio/.git` exists. If not, stop with a message pointing the user at `git@github.com:koolamusic/studio.git` and instructing them to clone it to `~/.studio` before re-running.

5. **Create workspace dirs.** Under `~/.studio/$SLUG/`, `mkdir -p`:
   - one directory per value in the parsed `symlinks` map (i.e. each `target_name`), and
   - one directory per entry in `workspace_dirs`.

   For the shipped config this resolves to: `~/.studio/$SLUG/{jira,planning,retrospective,uat,memory,memory/archive,skills,hooks}`. The command must compute this list from the parsed YAML, not from a hardcoded list.

6. **Move existing project state.** Iterate over each `(link_name, target_name)` pair from the parsed `symlinks` map. For each pair:
   - If `$PROJECT_ROOT/$link_name` exists as a **real directory** (not a symlink) and is non-empty:
     - If `~/.studio/$SLUG/$target_name` is non-empty, STOP and use `AskUserQuestion` to surface the conflict — merge strategy is out of P1 scope.
     - Else `mv "$PROJECT_ROOT/$link_name"/* "$PROJECT_ROOT/$link_name"/.[!.]* "$HOME/.studio/$SLUG/$target_name/" 2>/dev/null || true` (move contents, including dotfiles; tolerate empty directories), then `rmdir "$PROJECT_ROOT/$link_name"`.
   - If `$PROJECT_ROOT/$link_name` is a **symlink** whose resolved target starts with `$HOME/.studio/$SLUG/$target_name`: leave it in place (already correct).
   - If `$PROJECT_ROOT/$link_name` is a symlink pointing elsewhere: remove it (the replacement symlink will be created in step 7).
   - If `$PROJECT_ROOT/$link_name` does not exist: nothing to move; step 7 will create the symlink fresh.

7. **Write symlinks.** For each `(link_name, target_name)` pair in `symlinks`: if `$PROJECT_ROOT/$link_name` is not already a correct symlink (per the step 6 check), run `ln -s "$HOME/.studio/$SLUG/$target_name" "$PROJECT_ROOT/$link_name"`. Skip when the correct symlink is already present — this keeps the command idempotent on re-run.

8. **Install session-start hook into workspace.** Copy `${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh` to `~/.studio/$SLUG/hooks/session-start.sh` (overwrite unconditionally — the plugin ships the canonical version) and `chmod +x` the destination. This keeps the workspace self-contained so the hook keeps working even when the plugin is unavailable.

9. **Sync the managed `.gitignore` block** (inline logic — no external helper script):

   1. Read `$PROJECT_ROOT/.gitignore` into memory. If the file does not exist, treat its current content as empty string.
   2. Let `MARKER_START = gitignore.marker_start` and `MARKER_END = gitignore.marker_end` (from the parsed studio.yaml in step 1 — not hardcoded).
   3. Build the managed `BLOCK` content by concatenating, in order:
      - `MARKER_START` on its own line,
      - each item in `gitignore.entries` on its own line (verbatim — no leading slash, one per line),
      - `MARKER_END` on its own line.
   4. Scan the current `.gitignore` for `MARKER_START` and `MARKER_END` and branch on the marker state:
      - **Both markers present, `MARKER_START` appears before `MARKER_END`:** replace every line from `MARKER_START` through `MARKER_END` (inclusive) with `BLOCK`. Every line outside that range must be preserved verbatim, byte-for-byte. This is the re-sync path.
      - **Neither marker present:** append `BLOCK` to the end of the file. If the existing file is non-empty and does not already end with a blank line, prepend a single blank line to the appended block so the markers are visually separated from prior content.
      - **Malformed — only one marker present, or `MARKER_END` appears before `MARKER_START`, or either marker appears more than once:** STOP immediately and report the malformed state to the user. Do not guess — the `.gitignore` has diverged from studio's expectations and needs manual repair.
   5. Write the resulting content back to `$PROJECT_ROOT/.gitignore`.

10. **Write `.workspacerc`.** Write a JSON breadcrumb to `$PROJECT_ROOT/.workspacerc` with the following shape, pretty-printed (2-space indent) and ending in a trailing newline:

    ```json
    {
      "version": 1,
      "workspace": "~/.studio/<slug>",
      "symlinks": [".jira", ".planning", ".retrospective", ".uat"]
    }
    ```

    where `<slug>` is the actual slug resolved in step 3, and the `symlinks` array lists **exactly the symlinks that were actually created at the project root** (the subset of studio.yaml's `symlinks:` keys that this project uses). For `/studio:setup`, that's the full set from studio.yaml since setup creates all declared symlinks. For partial adoption (some symlinks omitted by choice), include only the ones actually written. The session-start hook reads this field to know what drift to check for.

    `.workspacerc` is **machine-local** — it lives in the project root but is gitignored via the managed block from step 9 (different machines may store the workspace at different absolute paths, so committing it would leak a machine-specific value). Do not `git add` it.

11. **Wire hook into project settings.** Read `$PROJECT_ROOT/.claude/settings.json`. If the directory or file does not exist, create `$PROJECT_ROOT/.claude/` and initialize `settings.json` with `{}`. For each entry in the parsed `hooks.SessionStart` list:
    - Take the entry's `command` string and replace the literal token `${WORKSPACE}` with the absolute, `~`-expanded path `$HOME/.studio/$SLUG`.
    - Ensure `settings.hooks.SessionStart` exists (create as an empty array if missing), then merge the entry (with the substituted command) into it.
    - Deduplicate by command string — if an entry with the same resolved command already exists in `settings.hooks.SessionStart`, do not append a second copy. This preserves idempotency across re-runs.

    Write the result back using stable JSON formatting (2-space indent, trailing newline).

12. **Commit in the project repo.** Stage `.gitignore`, and stage `.claude/settings.json` as well if it was created or modified by step 11. Do **NOT** `git add .workspacerc` — it is intentionally gitignored via the managed block in step 9 and must remain machine-local. Then:

    ```bash
    git commit -m "chore: initialize studio workspace ($SLUG)"
    ```

    If there is nothing staged (fully idempotent re-run with no drift), skip the commit and note it in the report. Never `git push`.

13. **Commit in the `~/.studio` repo.** Change into `~/.studio`, stage the entire `$SLUG/` subtree, and commit:

    ```bash
    cd ~/.studio
    git add "$SLUG/"
    git commit -m "feat($SLUG): initialize workspace"
    ```

    If the working tree has nothing to commit (idempotent re-run with no workspace-side drift), skip the commit and note it in the report. Never `git push` — the studio repo is pushed manually by the user.

14. **Report.** Print a short summary:
    - slug (`$SLUG`)
    - workspace path (`~/.studio/$SLUG`)
    - number of symlinks created (vs. already-correct)
    - gitignore action: `created` | `updated (block replaced)` | `appended (block added)` | `unchanged`
    - whether `.workspacerc` was written or already matched
    - whether commits were created in the project repo and the studio repo (or were no-ops)
    - next step hint: "Run `/studio:sync` to re-apply the managed gitignore block after future studio.yaml updates."

## Hard rules

- **Idempotent.** Re-running `/studio:setup` on an already-initialized project is a safe no-op for the move/symlink/hook-install steps, but it always re-syncs the managed `.gitignore` block (which is the only part that may legitimately change on re-run when `studio.yaml` is updated upstream).
- **Never auto-push.** Both commits (project repo and `~/.studio`) stop at `git commit`. The user pushes manually — there is no `git push` anywhere in this command.
- **`studio.yaml` is the source of truth.** No hardcoded symlink names, workspace directory names, gitignore entries, marker strings, or hook commands live inside this command. Every such value is read at runtime from `${CLAUDE_PLUGIN_ROOT}/templates/studio.yaml` and used by name. Literal examples in the prose above are illustrative only.
- **Managed gitignore block is replaced wholesale** between the two markers. Content outside the markers is preserved byte-for-byte — do not touch it, do not reorder it, do not normalize whitespace around it.
- **Conflicts STOP.** Non-empty target in the workspace when moving project state, a malformed marker state in `.gitignore`, or a slug clash with an unrelated existing workspace all halt the command and surface via `AskUserQuestion`. Never silently overwrite user data.
