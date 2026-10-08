#!/usr/bin/env bash
# Runs the newest Playwright Chromium with the flags a VM without unprivileged
# user namespaces needs. diagram.sh points SEECODE_CHROME here when no system
# Chrome is on PATH; set SEECODE_CHROME yourself to use another browser.
set -u
bin="$(ls -d "$HOME"/.cache/ms-playwright/chromium-*/chrome-linux*/chrome \
             "$HOME"/.cache/ms-playwright/chromium-*/chrome-mac*/Chromium.app/Contents/MacOS/Chromium 2>/dev/null | sort -V | tail -1)"
if [ -z "$bin" ] || [ ! -x "$bin" ]; then
  echo "no Playwright Chromium under ~/.cache/ms-playwright" >&2
  exit 1
fi
exec "$bin" --no-sandbox --disable-gpu "$@"
