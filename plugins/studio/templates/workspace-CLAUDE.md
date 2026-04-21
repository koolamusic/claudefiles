# Studio Workspace: {{workspace_slug}}

This workspace hosts cross-session state for the `{{workspace_slug}}` project. It is READ-ONLY reference for Claude Code sessions.

## Memory archive

`memory/archive/<host>/<iso>/` contains snapshots of local Claude memory from each machine that has run `/studio:sync` on this project.

**Rules for Claude:**
- The archive is READ-ONLY reference. Never auto-import, never merge into session context, never edit.
- Local `~/.claude/projects/<slug>/memory/` is authoritative. The archive is historical record.
- Consult the archive only when the user asks, or when a question clearly requires cross-machine context.
- The user controls adoption. If something in the archive is worth pulling into local memory, the user runs `/studio:adopt`.

## Workspace layout

- `memory/archive/<host>/<iso>/` — append-only memory snapshots (one dir per sync).
- `planning/`, `jira/`, `retrospective/`, `uat/` — workflow state mirrored from project symlinks.
- `skills/`, `hooks/` — project-scoped tools copied at setup time.

## How adoption works

- `/studio:adopt` reads the archive, diffs against local memory, and asks the user which fragments to copy in.
- The command never writes to local memory without explicit per-fragment confirmation.
- Before overwriting, the command creates `<file>.local-backup-<iso>` in the local memory dir.

## Hard rules (reminder)

- Archive is append-only.
- Local memory is authoritative; archive is reference.
- `/studio:sync` is manual only. No auto-trigger after `/studio:adopt`.
