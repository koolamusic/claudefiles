---
description: Archive a completed project's workspace — git mv ~/.studio/<slug> into ~/.studio/_archive/, then clean up the project root (symlinks, .workspacerc, session hook) if a checkout is present. Never deletes workspace content.
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
argument-hint: "[<slug>] (defaults to the current project's workspace)"
---

# /studio:archive

For projects that are completed or wound down. The workspace moves out of the
`~/.studio/` root into `~/.studio/_archive/<slug>/` — a fixed convention, like
`.workspacerc` and `_index.md`, not a studio.yaml value — so the store root
lists only active work. Git history preserves everything; nothing is deleted.

Archiving is a store-side move plus a machine-local cleanup. Other machines
with checkouts of the same project clean themselves up on their next session
(their session-start hook fails to resolve the workspace and points here).

## Steps

1. **Resolve slug.** If `$ARGUMENTS` names a slug, use it. Otherwise run
   `git rev-parse --show-toplevel` and read `$PROJECT_ROOT/.workspacerc` —
   the `workspace` field's basename is the slug. If neither yields a slug,
   stop and ask.

2. **Verify the workspace.** Confirm `~/.studio/$SLUG` exists and
   `~/.studio/.git` exists. If `~/.studio/_archive/$SLUG` already exists,
   STOP — a previous archive of the same slug is in place; never overwrite.
   Surface via `AskUserQuestion` (suffix the new archive, or cancel).

3. **Confirm intent.** Archiving is meant for completed work. Use
   `AskUserQuestion` to confirm: show the slug, its last workspace commit
   touching it (`cd ~/.studio && git log -1 --format='%h %ad %s' --date=short -- $SLUG/`),
   and proceed/cancel. Skip the question only if the user's invocation
   already named the slug explicitly.

4. **Move.** In `~/.studio`: `mkdir -p _archive && git mv "$SLUG" "_archive/$SLUG"`.
   `git mv` only carries tracked files — afterwards check `[[ -e "$SLUG" ]]`
   for untracked leftovers; if any remain, `mv` them into `_archive/$SLUG/`
   preserving relative paths, then remove the empty source dir.

5. **Commit the store.** `git add -A "_archive/$SLUG" && git commit -m "chore: archive $SLUG (completed)"`.
   Never `git push` — the studio repo is pushed manually by the user.

6. **Clean up the local checkout (machine-local, skip if absent).** If a
   project checkout is available (step 1 found `.workspacerc`, or the user
   points at one):
   - Remove each project-root symlink that resolves into `~/.studio/$SLUG`
     (whether or not it is still declared in studio.yaml — retired links like
     `.uat` count). `rm` the link only, never a real directory.
   - Remove `.workspacerc`.
   - Edit `.claude/settings.local.json`: drop the studio SessionStart hook
     entry whose command points into `~/.studio/$SLUG/hooks/`. Preserve every
     other key verbatim. Remove the file only if it becomes `{}`.
   - Leave the managed `.gitignore` block in place — it is inert without the
     symlinks and keeps a future re-adoption cheap. No project-side commit is
     needed unless the user asks.

7. **Report.** Print: the archive path, the store commit SHA, which local
   cleanup actions ran (or that no checkout was present), and a reminder that
   other machines clean up on their next session in that project.

## Hard rules

- **Never delete workspace content.** Archive is a move; `_archive/` is the
  record. The only `rm` this command ever runs is on project-root symlinks.
- **Never `git push`.**
- **Never overwrite an existing `_archive/$SLUG`.**
- **Un-archiving is manual:** `cd ~/.studio && git mv "_archive/$SLUG" "$SLUG"`,
  then `/studio:setup` in the checkout to re-link.
