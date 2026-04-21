---
description: Adopt memory fragments from the studio workspace archive into local Claude memory. Opt-in, per-fragment confirmation via AskUserQuestion. Backs up local on overwrite. Never auto-triggers.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: "[--host <name>] [--since <YYYY-MM-DD>] [--all]"
---

## Overview

Bring cross-machine Claude memory into the local memory dir. The archive at `<workspace>/memory/archive/<host>/<iso>/` is read-only reference; this command presents candidates, the user picks, the command copies (backing up overwrites). Never writes without per-fragment confirmation.

## Arguments

- `--host <name>` — restrict enumeration to a single host (default: all hosts).
- `--since <YYYY-MM-DD>` — restrict to snapshots from this date forward (UTC).
- `--all` — skip the `latest-per-host` reduction and consider every snapshot. Rarely needed.

## Steps

1. **Resolve workspace and config.**
   - Read `.workspacerc` from `pwd` (the project root). If the file is missing, stop with `[studio] not a studio-managed project (no .workspacerc); run /studio:setup first` and exit 1.
   - Parse the JSON `workspace` field; expand a leading `~` via `${HOME}`. Call this `WORKSPACE`.
   - If `[[ ! -d "$WORKSPACE" ]]`, stop with `[studio] workspace dir not found: $WORKSPACE` and exit 1.
   - Read `${WORKSPACE}/studio.yaml`. Extract (using `yq`):
     ```bash
     archive_dir=$(yq eval '.memory.archive_dir // "memory/archive"' "${WORKSPACE}/studio.yaml")
     RAW_SOURCE=$(yq eval '.memory.source' "${WORKSPACE}/studio.yaml")
     default_filter=$(yq eval '.adoption.default_filter // "latest-per-host"' "${WORKSPACE}/studio.yaml")
     preview_chars=$(yq eval '.adoption.preview_chars // 200' "${WORKSPACE}/studio.yaml")
     backup_on_overwrite=$(yq eval '.adoption.backup_on_overwrite // true' "${WORKSPACE}/studio.yaml")
     backup_suffix=$(yq eval '.adoption.backup_suffix // ".local-backup-{iso}"' "${WORKSPACE}/studio.yaml")
     ```
   - If `preview_chars` is `0` or negative, treat it as `200` silently.
   - Derive `PROJECT_HASH` from `pwd`. `${PROJECT_HASH}` is expanded by this command, not by Claude Code's plugin loader. The two-stage sed pipeline is the canonical derivation:
     ```bash
     PROJECT_HASH=$(pwd | sed 's|/|-|g' | sed 's|\.|-|g')
     ```
   - Expand `memory.source` with `PROJECT_HASH` and `~` to produce `LOCAL_MEMORY`:
     ```bash
     LOCAL_MEMORY="${RAW_SOURCE//\$\{PROJECT_HASH\}/$PROJECT_HASH}"
     LOCAL_MEMORY="${LOCAL_MEMORY/#\~/$HOME}"
     ```

2. **Enumerate snapshots.**
   - `ARCHIVE_ROOT="${WORKSPACE}/${archive_dir}"`.
   - If `[[ ! -d "$ARCHIVE_ROOT" ]]` or `find "$ARCHIVE_ROOT" -mindepth 2 -maxdepth 2 -type d | wc -l` reports `0`, stop with `[studio] nothing to adopt: archive is empty at $ARCHIVE_ROOT` and exit 0 (graceful no-op, not an error).
   - Collect every `<host>/<iso>/` pair by running `find "$ARCHIVE_ROOT" -mindepth 2 -maxdepth 2 -type d`. Each resulting path decomposes into `(host, iso)` — the last two path components.
   - Apply filters parsed from `$ARGUMENTS`:
     - `--host <name>` → keep pairs where `host == name`.
     - `--since <YYYY-MM-DD>` → keep pairs where `iso >= date` (lexical comparison is safe because iso starts `YYYY-MM-DD`).

3. **Reduce to candidate set.**
   - If `--all` was passed in `$ARGUMENTS`, keep every pair.
   - Else (default `latest-per-host`): for each distinct `host`, keep only the pair whose `iso` is lexically greatest.
   - After reduction, the set is `{(host_i, iso_i, snapshot_dir_i)}_N`. If `N == 0`, exit 0 with `[studio] no snapshots matched filters.`

4. **Diff against local memory.**
   - For each `(host, iso, snapshot_dir)`:
     - For each file under `snapshot_dir` EXCEPT `MEMORY.md` (the index is handled separately in step 8):
       - Let `basename=$(basename "$file")`.
       - Let `local_path="$LOCAL_MEMORY/$basename"`.
       - If `[[ ! -f "$local_path" ]]`: classify the fragment as `NEW`.
       - Else if `! cmp -s "$file" "$local_path"`: classify as `DIFFERS`. (`cmp -s` is POSIX; `diff -q` is an equivalent fallback.)
       - Else: classify as `IDENTICAL`; skip — do not surface.
   - Build a list `CANDIDATES = [(host, iso, basename, class, snapshot_path, preview)]` containing every `NEW` and `DIFFERS` entry. `preview = $(head -c "$preview_chars" "$file" | tr '\n' ' ')`.

5. **Bail gracefully if nothing to offer.**
   - If `len(CANDIDATES) == 0`, exit 0 with `[studio] nothing new to adopt; all archived fragments match local memory.`

6. **Surface candidates via AskUserQuestion (multiSelect).**
   - Invoke AskUserQuestion exactly once with `multiSelect: true`. Payload shape:
     ```
     question: "Which archived fragments do you want to adopt into local memory?"
     multiSelect: true
     options:
       - label: "[<host>] <basename> (<class>)"
         description: "<iso> — <preview truncated to preview_chars>"
         value: "<host>||<iso>||<basename>"
       ...
     ```
   - The `value` field encodes `host`, `iso`, and `basename` joined by `||`; step 7 splits on `||` to reconstruct the snapshot path.
   - If the user selects zero options, exit 0 with `[studio] no fragments adopted.`

7. **Copy selected fragments — back up on overwrite.**
   - Compute a single adoption timestamp up-front so every backup in this run shares the same `{iso}` value:
     ```bash
     BACKUP_ISO=$(date -u +%Y-%m-%dT%H-%M-%SZ)
     ```
   - For each selected `value`:
     - Split into `(host, iso, basename)` on `||`.
     - Reconstruct `snapshot_path="${ARCHIVE_ROOT}/${host}/${iso}/${basename}"`.
     - `local_path="$LOCAL_MEMORY/$basename"`.
     - **DIFFERS branch** (`[[ -f "$local_path" ]]` at copy time, and `backup_on_overwrite == true`):
       - Expand the backup suffix template: `backup_name=$(echo "$backup_suffix" | sed "s|{iso}|$BACKUP_ISO|g")`.
       - `backup_path="${local_path}${backup_name}"` (e.g. `foo.md.local-backup-2026-04-19T12-34-56Z`).
       - `cp "$local_path" "$backup_path"`. Verify via `[[ -f "$backup_path" ]]` before overwriting. If verification fails, abort this fragment only — emit `[studio] backup failed for $basename; skipping.` and continue to the next selected value.
     - **NEW branch** (`[[ ! -f "$local_path" ]]`): `mkdir -p "$LOCAL_MEMORY"` (in case the local memory dir does not exist yet).
     - `cp "$snapshot_path" "$local_path"`.
     - Accumulate into the `ADOPTED` list as `(host, iso, basename, class, snapshot_path, backup_path_or_none)`.

8. **Rebuild MEMORY.md index — append-only.**
   - `local_index="$LOCAL_MEMORY/MEMORY.md"`. If the file does not exist, create it empty (`: > "$local_index"`).
   - For each `(host, iso, basename, class, snapshot_path, _)` in `ADOPTED` where `class == NEW`:
     - Locate the archived index for this fragment's snapshot: `archived_index="${snapshot_path%/*}/MEMORY.md"` (one level up from the fragment file).
     - Grep the archived index for a line whose link target matches `basename`: `grep -E "]\(${basename}\)" "$archived_index"`.
     - If a matching line is found, append it verbatim to `local_index`.
     - If no match (archived index drift), synthesize a placeholder pointer and append it. The title is the basename with extension stripped, underscores/hyphens turned into spaces, then title-cased:
       ```bash
       title=$(echo "${basename%.md}" | sed 's/[-_]/ /g' | awk '{for(i=1;i<=NF;i++)$i=toupper(substr($i,1,1)) substr($i,2)}1')
       echo "- [${title}](${basename}) — Adopted from ${host} snapshot ${iso}; update description." >> "$local_index"
       ```
       Track placeholders in a counter for the final report.
   - For each `(…, class, …)` where `class == DIFFERS`: do NOT touch `local_index`. The existing pointer stays — the description was user-authored and the fragment's identity did not change; only the pointed-to file was updated.
   - Dedupe `local_index` after appending, keyed by the bare filename (the link target inside the parentheses). This keeps MEMORY.md append-only across repeated adoptions:
     ```bash
     awk -F '[][]' '{key=$2} !seen[key]++' "$local_index" > "$local_index.tmp" && mv "$local_index.tmp" "$local_index"
     ```
     Note: the dedupe key is the link title between `[` and `]`. If two archived hosts contribute a fragment with the same filename but different titles, the first-seen title wins and the user should edit manually.

9. **Report.**
   - Emit a single summary block to stdout:
     ```
     [studio] Adoption complete.
       Adopted: <count>
         <basename> (NEW)     — from <host> <iso>
         <basename> (DIFFERS) — from <host> <iso> (backup: <backup_path>)
       Index updated: <index_appends> new pointer(s), <placeholder_count> placeholder(s) requiring description edit.
       Next: review "$LOCAL_MEMORY/MEMORY.md" and adjust titles/descriptions.
     ```
   - Do NOT commit any local memory changes. The local memory dir lives under `~/.claude/projects/<slug>/memory/` — outside the workspace git repo and outside the project repo — and is not version controlled by studio.
   - Do NOT auto-trigger `/studio:sync`. The next user-invoked sync will snapshot the updated local state.

## Hard rules

- **Opt-in only.** This command never auto-triggers; the user invokes `/studio:adopt` explicitly.
- **Per-fragment confirmation required.** Nothing is written to local memory without the user selecting that specific fragment in the AskUserQuestion step.
- **Backup before overwrite.** Every DIFFERS adoption creates `<file><backup_suffix-expanded>` in the local memory dir first, verifies the backup exists, then overwrites. If the backup fails, the overwrite is skipped.
- **Archive stays read-only.** This command only reads from the workspace archive. It never writes, moves, deletes, or rebuilds anything under `<workspace>/memory/archive/`.
- **MEMORY.md index is append-only and dedupe-by-filename.** Existing pointers for DIFFERS fragments are preserved. NEW fragments get their archived pointer (or a placeholder if the archived index didn't have one). After appending, dedupe by bare filename so re-adoption doesn't produce duplicate lines.
- **No auto-sync.** After adoption, the user re-runs `/studio:sync` manually if they want the newly-adopted local state to appear in a future archive snapshot.
- **PROJECT_HASH is expanded by this command.** Not by Claude Code's plugin loader. The two-stage `sed 's|/|-|g' | sed 's|\.|-|g'` is the canonical derivation.
