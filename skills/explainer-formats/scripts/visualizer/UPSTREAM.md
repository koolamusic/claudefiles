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

Drew's rule for this repo: it deploys to every machine he owns, so the
vendored engine makes no network calls at runtime. Upstream loads Google
Fonts into every page, fetches them again to embed in SVG exports, and loads
its GIF/MP4/WebM encoders from jsDelivr inside the page's Export menu. The
patches below replace all of that with bundled files. The only runtime fetch
left is `brand <url>` (user-initiated) and, when a brand profile names Google
or self-hosted fonts, the fetch of those brand fonts (user-configured).

Each patch is a `git diff` against the pristine copy, stored as
`patches/NN-<name>.patch`; apply them from the repo root with `git apply`.

| Patch | File, function | What it does |
|---|---|---|
| `01-fonts-local-module` | `scripts/lib/fonts-local.mjs` (new) | `localFontCss()` builds `@font-face` rules with base64 data URIs from `assets/fonts/`; `encoderScripts()` wraps the three `scripts/vendor/` encoders as inert `<script type="text/plain" id="sc-lib-*">` blocks. Excluded from the re-sync rsync so it survives. |
| `02-page-embed-fonts-and-encoders` | `scripts/lib/page.mjs`, `pageHtml` | Drops the Google Fonts `<link rel="preconnect">` and `<link id="sc-fonts">`, emits `<style id="sc-fonts">` with the local faces instead (Kalam only when sketchy), and appends the encoder blocks before the viewer script. `FONTS_HREF` is no longer imported; `tokens.mjs` is untouched. |
| `03-viewer-offline-export` | `scripts/lib/viewer/viewer.client.js`: `LIBS`/`lib()`, `embeddedFonts()`, `frameSvg()` | `lib()` evaluates the inline encoder block (or reuses a `window` global the CLI exporter injected) instead of `import()` from jsDelivr. `embeddedFonts()` starts from the `#sc-fonts` text and only fetches brand families from `link.sc-brand-fonts`. `frameSvg()` falls back to the inline CSS, not an `@import` of the link href. |
| `04-svg-export-bundled-faces` | `scripts/lib/export/svg.mjs`, `svgFromHtml` | Copies the `#sc-fonts` rules into the SVG's `<style>`; `@import` lines are built from brand hrefs only. |
| `05-fonts-embed-skip-bundled` | `scripts/lib/export/fonts.mjs`, `embedFonts` | "no font faces returned" is an error only when there were Google imports to resolve, so an SVG whose faces are already inline reports `ok: true`. |

What this adds to each generated page, measured on a 5-node architecture
diagram: fonts as base64 about 228 KB, encoders about 166 KB; the page grew
from 171 KB to 565 KB. A sketchy page carries Kalam too (about 37 KB more).
An exported SVG grew from 95 KB (no fonts, offline) to 322 KB.

## Bundled fonts

`assets/fonts/` holds the latin subset of each face, downloaded once from
Google Fonts on 2026-10-08; `manifest.json` records family, style, weight,
unicode range, byte size and the exact source URL of each file. Google serves
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
   `https://` URL: the vendored copy must not make network calls at runtime
   except the user-initiated `brand <url>` fetch.
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
   `scripts/visualizer`, and run `node --test test/*.test.mjs` there.
6. Bump the commit hash and date at the top of this file and in `NOTICE.md`.
