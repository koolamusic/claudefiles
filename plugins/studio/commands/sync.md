---
description: Re-sync a studio-initialized project. Re-reads studio.yaml, re-applies the managed .gitignore block, validates all symlinks resolve into the workspace slug, reports drift. Idempotent and non-destructive — never moves project state or modifies the workspace contents. (BASE behavior for P1; memory archival lands in P3.)
allowed-tools: Bash, Read, Write, Edit
argument-hint: [--dry-run] [--message <msg>]
---

Re-sync the current project against its studio workspace. Unlike `/studio:setup`, this command assumes initialization has already happened — it re-applies the managed gitignore block and validates symlinks, but never moves project state. Run after pulling studio.yaml changes from the plugin, or when the project's `.gitignore` has drifted.

Optional flags:

- `--dry-run` — print every command that would run; exit 0 with no side effects (no file writes, no commits).
- `--message <msg>` — override the default commit message used when the managed gitignore block is updated. Does not change workspace-side commit message.

## Memory archival (optional)

This section runs BEFORE the main step sequence below. It archives the current Claude project memory snapshot into the studio workspace. All sub-steps are gated by `memory.enabled` in `studio.yaml` — if disabled, the entire section skips silently and control flows straight to the main Steps below. Under `--dry-run`, every mutating sub-step (mkdir, cp, git add/commit) prints instead of executing.

Resolve `WORKSPACE` first (same as step 3 below): `PROJECT_ROOT=$(git rev-parse --show-toplevel)`; read `.workspacerc`; expand leading `~`. All sub-steps in this section assume `$WORKSPACE` is set.

1. **Read studio.yaml memory config.** Resolve the studio config path the same way the main Steps do — but for memory archival we read from the workspace-local `studio.yaml` (copied there at `/studio:setup` time). Run:
   ```bash
   MEMORY_ENABLED=$(yq eval '.memory.enabled // false' "${WORKSPACE}/studio.yaml")
   ```
   If `MEMORY_ENABLED` is `false` or the key is missing (yq returns `false` for a missing path thanks to the `// false` default), print `[studio] memory archival disabled; skipping.` to stderr and jump to the main Steps section below. No exit code, no side effect.

2. **Resolve source path via PROJECT_HASH expansion.** Capture the raw source template from studio.yaml and expand `${PROJECT_HASH}` inline. `${PROJECT_HASH}` is expanded by this command, not by Claude Code's plugin loader. The two-stage sed pipeline is load-bearing — it mirrors the directory-naming convention Claude Code uses under `~/.claude/projects/`:
   ```bash
   RAW_SOURCE=$(yq eval '.memory.source' "${WORKSPACE}/studio.yaml")
   PROJECT_HASH=$(pwd | sed 's|/|-|g' | sed 's|\.|-|g')
   MEMORY_SOURCE="${RAW_SOURCE//\$\{PROJECT_HASH\}/$PROJECT_HASH}"
   # expand leading ~ to $HOME
   MEMORY_SOURCE="${MEMORY_SOURCE/#\~/$HOME}"
   ```
   If `[[ ! -d "$MEMORY_SOURCE" ]]`, print `[studio] no memory dir at $MEMORY_SOURCE; skipping archival.` to stderr and jump to the main Steps section below. No exit code, no side effect.

3. **Build archive target from hostname + iso.** Read `memory.archive_dir` (default `memory/archive`) and `memory.path_template` (default `{hostname}/{iso}`) from studio.yaml:
   ```bash
   archive_dir=$(yq eval '.memory.archive_dir // "memory/archive"' "${WORKSPACE}/studio.yaml")
   path_template=$(yq eval '.memory.path_template // "{hostname}/{iso}"' "${WORKSPACE}/studio.yaml")
   HOSTNAME_SHORT=$(hostname -s)
   ISO=$(date -u +%Y-%m-%dT%H-%M-%SZ)
   REL_PATH=$(echo "$path_template" | sed "s|{hostname}|$HOSTNAME_SHORT|g; s|{iso}|$ISO|g")
   ARCHIVE_TARGET="${WORKSPACE}/${archive_dir}/${REL_PATH}"
   ```
   **Append-only guard.** If `[[ -e "$ARCHIVE_TARGET" ]]`, abort with `[studio] archive target already exists: $ARCHIVE_TARGET — this violates append-only; aborting.` and exit 1. This should be impossible given the second-resolution iso stamp, but the check is cheap and the invariant is load-bearing.

4. **Create and copy.** Create the target directory and copy the full memory tree:
   ```bash
   mkdir -p "$ARCHIVE_TARGET"
   cp -R "$MEMORY_SOURCE/." "$ARCHIVE_TARGET/"
   ```
   Every file under `$MEMORY_SOURCE` is preserved, including `MEMORY.md` and any nested references.

5. **Report.** Print the archive location and file count. Use a shell fallback for the relative path (avoids GNU-only `realpath --relative-to`):
   ```bash
   REL_OUT="${ARCHIVE_TARGET#$WORKSPACE/}"
   N=$(find "$ARCHIVE_TARGET" -type f | wc -l | tr -d ' ')
   echo "[studio] memory archived: $REL_OUT ($N files)"
   ```

6. **Commit inside the workspace.** Change into the workspace git repo and commit the new archive directory. Never push. If `git add` fails or nothing is staged (e.g. workspace is a fresh dir with no `.git`), emit a one-line warning to stderr and continue — the on-disk archive is the load-bearing outcome; the commit is convenience:
   ```bash
   (cd "$WORKSPACE" && git add "${archive_dir}/${REL_PATH}" && git commit -m "studio: archive memory ($HOSTNAME_SHORT $ISO)") \
     || echo "[studio] warn: workspace commit skipped (no git repo or nothing staged)" >&2
   ```
   Under `--dry-run`, print the commands instead of executing them.

### Hard rules

- Archive is append-only. Never overwrite a prior snapshot directory.
- `memory.enabled: false` must skip the entire section silently (stderr line is fine; no exit code, no side effect).
- `${PROJECT_HASH}` is expanded by the command, not by Claude Code's plugin loader.

## Steps

1. **Parse flags.** Inspect `$ARGUMENTS`. Recognize `--dry-run` (boolean) and `--message <msg>` (string; takes the next token). Any other argument is an error — stop and explain. When `--dry-run` is set, every step that would mutate state (writes, `git add`, `git commit`) must only be printed, never executed.

2. **Locate config.** Read `${CLAUDE_PLUGIN_ROOT}/templates/studio.yaml`. Parse the same fields as `/studio:setup`: `symlinks` (map of link_name → target_name), `gitignore.marker_start`, `gitignore.marker_end`, `gitignore.entries` (list). Do not hardcode any of these values — they are the source of truth and may change between plugin versions.

3. **Locate project root + workspace.** Run `git rev-parse --show-toplevel` → `PROJECT_ROOT`. If not in a git repo, stop with an explanation. Read `$PROJECT_ROOT/.workspacerc`. If `.workspacerc` is absent, stop and suggest running `/studio:setup` first. Parse the JSON `workspace` field, expand a leading `~` to `$HOME` → `WORKSPACE`. Confirm `[[ -d "$WORKSPACE" ]]`; if the workspace directory is missing, stop with a message that points the user at the studio repo (`~/.studio/`) and `/studio:setup`.

4. **Validate symlinks (report-only).** For each `(link_name, target_name)` in `symlinks` from step 2, inspect `$PROJECT_ROOT/$link_name` and classify it into one of these drift categories:
   - `missing` — no entry at that path; record as drift.
   - `not-a-symlink` — real directory (not a symlink); record as drift. This likely means the user has uncommitted state in a misplaced directory — do not touch it.
   - `wrong-target` — symlink exists but its resolved target does not start with `$WORKSPACE/$target_name`; record as drift.
   - `ok` — symlink exists and resolves correctly into the workspace.

   Collect the drift report as `{missing: [...], not-a-symlink: [...], wrong-target: [...]}`. This step MUST be strictly report-only: do not create, remove, or modify any symlink; do not `mv` or `rm` any real directory. If drift count > 0, print the report at the end of step 8 and recommend `/studio:setup` to repair. Continue to step 5 regardless — gitignore re-sync is independent of symlink health.

5. **Re-sync managed .gitignore block.** Identical logic to `/studio:setup` step 9:
   - Read `$PROJECT_ROOT/.gitignore` into memory (create empty if missing).
   - Extract `MARKER_START` and `MARKER_END` from the parsed studio.yaml (step 2), not hardcoded.
   - Build `BLOCK` content: the start marker line, each entry from `gitignore.entries` on its own line, then the end marker line.
   - Scan the current `.gitignore` for both markers and handle the three cases:
     - **Both markers present in correct order:** replace everything between (and including) them with `BLOCK`. Preserve every line outside the markers verbatim.
     - **Neither marker present:** append `BLOCK` to EOF, preceded by a single blank line (insert the blank line only if the file is non-empty and does not already end in a blank line).
     - **Only one marker present, or markers in reversed order:** STOP and report. The `.gitignore` is malformed relative to studio's expectations; do not guess — let the user repair it by hand.
   - Write the result back to `$PROJECT_ROOT/.gitignore` (skip the write when `--dry-run` is active; print the proposed diff instead).

6. **Commit project repo if gitignore changed.** Default commit message: `chore: re-sync studio managed gitignore block`. If `--message <msg>` was provided, use `<msg>` verbatim instead. Run:
   ```bash
   git diff --quiet -- .gitignore || (git add .gitignore && git commit -m "<message>")
   ```
   Never `git push`. Under `--dry-run`, print the commands that would execute, but do not run them.

7. **Commit workspace repo if anything changed (future-proof scaffold).** `cd "$WORKSPACE/.." && git diff --quiet HEAD -- "$(basename "$WORKSPACE")/" || (git add "$(basename "$WORKSPACE")/" && git commit -m "chore: sync workspace")`. In P1, nothing under the workspace is modified by `/studio:sync`, so this commit is normally a no-op — the check is future-proofing for P3 when memory archival runs here. Never `git push`. Under `--dry-run`, print-only.

8. **Report.** Print:
   - Drift summary by category (counts for `missing`, `not-a-symlink`, `wrong-target`). If any drift > 0, recommend `/studio:setup` to repair.
   - Gitignore action: `unchanged` / `updated` / `malformed-stopped`.
   - Whether a project-side commit was created (and its short SHA) or skipped.
   - Whether a workspace-side commit was created (expected: skipped in P1).
   - If `--dry-run` was active, preface the report with `DRY RUN — no changes applied.`

## Not in P1

- **Memory archival is deferred to P3.** `/studio:sync` in P1 does not scan `~/.studio/<slug>/memory/` for archival candidates; the workspace-commit scaffold in step 7 stays because it is harmless when the tree is unmodified. The memory-archival motion (and the `/studio:adopt` flow it depends on) lands in Phase 3.

## Hard rules

- **Idempotent.** A healthy project produces zero file changes and zero commits on a second run.
- **Never auto-push.** Neither the project repo nor the workspace repo is pushed by this command. If a user runs `/studio:sync` and the workspace remote has diverged from HEAD, surface the situation at report time and let the user choose what to do — never force-push.
- **Never moves project state.** If symlink drift is detected (missing, not-a-symlink, wrong-target), this command reports it and recommends `/studio:setup`. It does NOT silently repair drift by moving files — the user may have uncommitted work inside a misplaced real directory, and only `/studio:setup` is authorized to move project state.
- **`studio.yaml` is the source of truth.** Symlink pairs, markers, and gitignore entries are read at runtime from `${CLAUDE_PLUGIN_ROOT}/templates/studio.yaml`. No hardcoded values in this command.
- **Managed-block replacement is wholesale.** Between `MARKER_START` and `MARKER_END`, the block is replaced byte-for-byte. Content outside the markers is preserved verbatim.
- **Malformed `.gitignore` stops the command.** If only one marker is present, or they appear in reversed order, the command stops and asks the user to repair by hand rather than guessing.
- **No memory archival in P1.** The workspace-commit step is a future-proof no-op scaffold. Memory archival logic (and any commands it depends on) belongs to P3 and is not invoked here.
- **`--dry-run` is hermetic.** Under `--dry-run`, every potentially mutating step must print instead of execute — no writes, no `git add`, no `git commit`. Exit code must be 0 if the dry run itself succeeded.
