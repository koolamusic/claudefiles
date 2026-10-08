#!/usr/bin/env bash
# Front door for the visualizer (vendored SeeCode engine). Keeps its config
# under ~/.cache/explainer-formats so nothing lands in ~/.seecode, turns the
# watermark off once, and finds a browser for raster export when none is on
# PATH. Everything else passes straight through to the engine.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
engine="$here/visualizer/scripts/seecode.mjs"
export SEECODE_HOME="${SEECODE_HOME:-$HOME/.cache/explainer-formats/visualizer}"

if ! command -v node >/dev/null 2>&1; then
  echo '{"ok":false,"error":"node not found","fix":"install Node 20 or newer"}'
  exit 1
fi

# First run: create the global config (no project .seecode/ is written) with the watermark off.
if [ ! -s "$SEECODE_HOME/config.json" ]; then
  mkdir -p "$SEECODE_HOME"
  node "$engine" config set watermark false --global >/dev/null
fi

# No system Chrome but a Playwright Chromium: use the no-sandbox wrapper.
if [ -z "${SEECODE_CHROME:-}" ] && ! command -v google-chrome chromium chromium-browser >/dev/null 2>&1; then
  if ls -d "$HOME"/.cache/ms-playwright/chromium-*/ >/dev/null 2>&1; then
    export SEECODE_CHROME="$here/chromium.sh"
  fi
fi

exec node "$engine" "$@"
