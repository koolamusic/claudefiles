# Upstream: SeeCode

This directory is a vendored copy of the SeeCode diagram engine. It is the
`visualizer` behind the explainer-formats diagram rung.

- Source: https://github.com/Aryanutkarsh/SeeCode
- Copied from commit `8c48bb8` (2026-10-03), upstream version 0.1.0
- License: MIT (see `LICENSE` here, identical to the upstream root LICENSE)
- Bundled encoders (gifenc, mp4-muxer, webm-muxer) are MIT; see `scripts/vendor/LICENSES.md`

## What was copied

`skills/seecode/` from upstream, as is: `SKILL.md`, `assets/`, `references/`,
`schemas/`, `scripts/` (including `scripts/vendor/`), plus the root `LICENSE`.
Only the directory name changed (`seecode` -> `visualizer`). Engine-internal
identifiers (`seecode.mjs`, `SEECODE_HOME`, `SEECODE_CHROME`, the `.seecode/`
config folder, UI strings) are left as upstream wrote them so re-sync diffs
stay clean.

## What was dropped

Upstream `commands/` (they need `${CLAUDE_PLUGIN_ROOT}`), `test/`, `docs/`,
`tools/`, `branding/`, `examples/`, and the repo-level policy files. The
explainer-formats skill drives the engine through `scripts/diagram.sh`, not
through upstream's command files.

## Local patches

(filled in by the offline patch set; see the `patches/` directory)

## Re-sync procedure

1. `git clone https://github.com/Aryanutkarsh/SeeCode /tmp/SeeCode` (or
   `git fetch` in an existing clone) and note the new HEAD hash.
2. `git -C /tmp/SeeCode diff 8c48bb8..origin/main -- skills/seecode` and
   review every hunk, in particular anything that adds a `fetch(` or a
   `https://` URL: the vendored copy must not make network calls at runtime
   except the user-initiated `brand <url>` fetch.
3. `rsync -a --delete --exclude UPSTREAM.md --exclude patches/ --exclude assets/fonts/ /tmp/SeeCode/skills/seecode/ scripts/visualizer/`
   then copy the root `LICENSE` over `scripts/visualizer/LICENSE` again.
4. Reapply the local patches in order:
   `for p in scripts/visualizer/patches/*.patch; do git apply "$p"; done`.
   A patch that no longer applies means upstream changed that function;
   redo it by hand against the description in the table above and
   regenerate the patch file.
5. Run the upstream tests against the copy: mirror the upstream repo into a
   scratch directory, replace its `skills/seecode` with a symlink to
   `scripts/visualizer`, and run `node --test test/*.test.mjs` there.
6. Bump the commit hash and date at the top of this file and in `NOTICE.md`.
