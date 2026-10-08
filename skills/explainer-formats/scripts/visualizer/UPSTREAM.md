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
Only the directory name changed (`seecode` -> `visualizer`). The local
patches below then remove what the explain skill does not use (upstream's
`SKILL.md`, the watermark and its PNGs, most importers), so the tree at HEAD
is smaller than the copy. Engine-internal
identifiers (`seecode.mjs`, `SEECODE_HOME`, `SEECODE_CHROME`, the `.seecode/`
config folder, UI strings) are left as upstream wrote them so re-sync diffs
stay clean.

## What was dropped

Upstream `commands/` (they need `${CLAUDE_PLUGIN_ROOT}`), `test/`, `docs/`,
`tools/`, `branding/`, `examples/`, and the repo-level policy files. The
explainer-formats skill drives the engine through `scripts/diagram.sh`, not
through upstream's command files.

## Local patches

This repo deploys to many machines, so the vendored engine makes no network
calls at runtime, none at all. Upstream
loads Google Fonts into every page, fetches them again to embed in SVG
exports, loads its GIF/MP4/WebM encoders from jsDelivr inside the page's
Export menu, and has a `brand <url>` command that fetches a site and can save
its fonts into a profile. The patches below replace the first three with
bundled files and remove the brand feature outright.

The patches are an ordered stack: each one is a `git diff` against the tree
as it stood after the previous patch, stored as `patches/NN-<name>.patch`.
Apply them from the repo root with `git apply`, in order; only the top patch
reverse-applies cleanly at HEAD. To verify the stack reproduces HEAD:

```
tmp=$(mktemp -d) && git archive a1d40ee skills/explainer-formats/scripts/visualizer | tar -x -C "$tmp" \
  && for p in skills/explainer-formats/scripts/visualizer/patches/*.patch; do git -C "$tmp" apply "$(pwd)/$p" || echo "FAILED $p"; done \
  && diff -r --exclude=UPSTREAM.md --exclude=patches --exclude=assets "$tmp/skills/explainer-formats/scripts/visualizer" skills/explainer-formats/scripts/visualizer && echo "stack reproduces HEAD"
```

(`assets/` is excluded because `assets/fonts/` is copied, not patched: the woff2 files are binary. A patch that only touches a file no later patch changes may also reverse-apply at HEAD; the stack order is what matters.)

| Patch | File, function | What it does |
|---|---|---|
| `01-fonts-local-module` | `scripts/lib/fonts-local.mjs` (new) | `localFontCss()` builds `@font-face` rules with base64 data URIs from `assets/fonts/`; `encoderScripts()` wraps the three `scripts/vendor/` encoders as inert `<script type="text/plain" id="sc-lib-*">` blocks. Excluded from the re-sync rsync so it survives. |
| `02-page-embed-fonts-and-encoders` | `scripts/lib/page.mjs`, `pageHtml` | Drops the Google Fonts `<link rel="preconnect">` and `<link id="sc-fonts">`, emits `<style id="sc-fonts">` with the local faces instead (Kalam only when sketchy), and appends the encoder blocks before the viewer script. `FONTS_HREF` is no longer imported; `tokens.mjs` is untouched. |
| `03-viewer-offline-export` | `scripts/lib/viewer/viewer.client.js`: `LIBS`/`lib()`, `embeddedFonts()`, `frameSvg()` | `lib()` evaluates the inline encoder block (or reuses a `window` global the CLI exporter injected) instead of `import()` from jsDelivr. `embeddedFonts()` starts from the `#sc-fonts` text and only fetches brand families from `link.sc-brand-fonts`. `frameSvg()` falls back to the inline CSS, not an `@import` of the link href. |
| `04-svg-export-bundled-faces` | `scripts/lib/export/svg.mjs`, `svgFromHtml` | Copies the `#sc-fonts` rules into the SVG's `<style>`; `@import` lines are built from brand hrefs only. |
| `05-fonts-embed-skip-bundled` | `scripts/lib/export/fonts.mjs`, `embedFonts` | "no font faces returned" is an error only when there were Google imports to resolve, so an SVG whose faces are already inline reports `ok: true`. (Superseded by 06, which deletes the file; kept so the series applies in order.) |
| `06-remove-brand` | `scripts/seecode.mjs` (`brand` case, command list); `scripts/lib/brand/brand.mjs` (deleted); `scripts/lib/export/fonts.mjs` (deleted); `scripts/lib/export/svg.mjs` (`svgFromHtml`, `exportSvg`); `scripts/lib/page.mjs` (`pageHtml`); `scripts/lib/render.mjs` (`renderSpec`); `scripts/lib/viewer/viewer.client.js` (`embeddedFonts`); `scripts/lib/config/config.mjs` (`cleanFonts` removed, `saveProfile`, `status`); `scripts/lib/tokens.mjs` (`FONTS_HREF` removed); `SKILL.md`, `references/settings.md`, `references/style-guide.md`, `references/onboarding.md` (deleted) | Removes the brand feature: the `brand` command, the site/CSS scraper, and every font path other than the bundled faces (no Google stylesheet links, no self-hosted `@font-face` passthrough, no width margin for brand typefaces). Palette profiles stay: `config profile save <slug> --accent #hex ...` writes colours only to `~/.seecode/profiles/`, reads nothing from the network, and profile `fonts` are no longer loaded. |
| `07-prune-to-core` | `scripts/lib/mark.mjs` (deleted), `assets/favicon.png`, `assets/mark-symbol.png`, `assets/mark-word.png` (deleted); `scripts/lib/page.mjs` (`buildPage`); `scripts/lib/tokens.mjs` (`.sc-mark` rules); `scripts/lib/config/config.mjs` (`watermark` default); `schemas/common.schema.json` (`watermark` description); `scripts/lib/importers/{d2,dot,canvas,models}.mjs` (deleted); `scripts/lib/importers/import.mjs` (imports, `FENCE`, dispatch); `scripts/seecode.mjs` (import usage); `SKILL.md`, `references/delivery.md` (deleted); `references/import.md`, `references/spec.md`, `references/settings.md`, `references/types/db-schema.md` | Prunes to what the explain skill uses. The watermark is gone: no mark strip, no favicon, no `watermark` setting; the spec key stays accepted by the schema and is ignored, because the graph schema has `additionalProperties: false` and older specs may still carry it. Importers are Mermaid and PlantUML only (plus the CSV/JSON row path that lives in `import.mjs` itself); every other detected format returns `ok:false, "<format> import is not bundled in this copy"`. Upstream's `SKILL.md` and `references/delivery.md` are dropped; the explain skill's own `SKILL.md` and `references/diagram.md` are the entry points, and nothing in the engine reads them at runtime. |
| `08-escape-encoder-text` | `scripts/lib/fonts-local.mjs`, `encoderScripts` | Escapes `</script` inside the inlined encoder text so a future encoder bump cannot end the `<script type="text/plain">` block early and truncate the page. |

What this adds to each generated page, measured on a 5-node architecture
diagram: fonts as base64 about 228 KB, encoders about 166 KB; the page grew
from 171 KB to 565 KB. A sketchy page carries Kalam too (about 37 KB more).
An exported SVG grew from 95 KB (no fonts, offline) to 322 KB.

## Bundled fonts

`assets/fonts/` holds the latin subset of each face, downloaded once from
Google Fonts on 2026-10-08; `manifest.json` records family, style, weight,
unicode range, byte size, sha256 and the exact source URL of each file. Google serves
one variable file for several requested weights, so those are stored once
with a weight range.

| Family | Files | License | Source |
|---|---|---|---|
| Fraunces (regular 400-500 variable, italic 400) | `fraunces-*.woff2` | SIL Open Font License 1.1 | https://fonts.google.com/specimen/Fraunces |
| IBM Plex Sans (400-600 variable) | `ibm-plex-sans-*.woff2` | SIL Open Font License 1.1 | https://fonts.google.com/specimen/IBM+Plex+Sans |
| IBM Plex Mono (400, 500) | `ibm-plex-mono-*.woff2` | SIL Open Font License 1.1 | https://fonts.google.com/specimen/IBM+Plex+Mono |
| Kalam (400, 700; sketchy look only) | `kalam-*.woff2` | SIL Open Font License 1.1 | https://fonts.google.com/specimen/Kalam |

## Re-sync procedure

1. `git clone https://github.com/Aryanutkarsh/SeeCode /tmp/SeeCode` (or
   `git fetch` in an existing clone) and note the new HEAD hash.
2. `git -C /tmp/SeeCode diff 8c48bb8..origin/main -- skills/seecode` and
   review every hunk, in particular anything that adds a `fetch(` or a
   `https://` URL: the vendored copy must not make network calls at runtime.
3. `rsync -a --delete --exclude UPSTREAM.md --exclude patches/ --exclude assets/fonts/ --exclude scripts/lib/fonts-local.mjs /tmp/SeeCode/skills/seecode/ scripts/visualizer/`
   then copy the root `LICENSE` over `scripts/visualizer/LICENSE` again.
4. Reapply the local patches in order:
   `for p in skills/explainer-formats/scripts/visualizer/patches/*.patch; do git apply "$p"; done`
   from the repo root (the patch paths are repo-relative).
   A patch that no longer applies means upstream changed that function;
   redo it by hand against the description in the table above and
   regenerate the patch file.
5. Run the upstream tests against the copy: mirror the upstream repo into a
   scratch directory, replace its `skills/seecode` with a symlink to
   `scripts/visualizer`, delete `test/brand.test.mjs`, `test/brand-fixtures/`
   and `test/watermark.test.mjs`, delete the fixtures for the removed importers
   (`deps.dot net.d2 tables.d2 board.drawio sketch.excalidraw model.dsl
   refund.bpmn schema.sql schema.prisma schema.dbml api.yaml`), and run
   `node --test --test-skip-pattern 'SKILL\.md|manifest carries the same version|dist zip|labels from imported files' test/*.test.mjs`
   there (the skipped names check upstream's own SKILL.md and release zip, and
   one label test that uses the draw.io fixture).
6. Bump the commit hash and date at the top of this file and in `NOTICE.md`.
