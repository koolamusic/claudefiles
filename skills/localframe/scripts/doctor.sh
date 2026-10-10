#!/usr/bin/env bash
# name: doctor.sh
# purpose: Pre-flight tool check for a take. Run from the take directory.
# usage: doctor.sh [browser|terminal|all]   (default: all)
# exit: 0 when every tool the mode needs is present, 1 otherwise. Installs nothing.
set -uo pipefail

mode=${1:-all}
missing=0

need() {
  local name=$1 hint=$2
  shift 2
  if out=$("$@" 2>&1 | head -1) && [ -n "$out" ]; then
    printf 'ok       %-11s %s\n' "$name" "$out"
  else
    printf 'MISSING  %-11s %s\n' "$name" "$hint"
    missing=1
  fi
}

need ffmpeg "install ffmpeg from the system package manager" ffmpeg -version
need ffprobe "ships with ffmpeg" ffprobe -version

if [ "$mode" = browser ] || [ "$mode" = all ]; then
  need node "install Node 18 or later" node --version
  need playwright "npm i -D playwright && npx playwright install chromium (in the take directory)" \
    node --input-type=module -e "const p = await import('playwright'); console.log('importable from ' + process.cwd())"
fi

if [ "$mode" = terminal ] || [ "$mode" = all ]; then
  need asciinema "cargo install asciinema (needs version 3)" \
    sh -c 'asciinema --version | grep -E "^asciinema 3"'
  need agg "cargo install --git https://github.com/asciinema/agg --tag v1.9.0 (the agg crate on crates.io is unrelated)" agg --version
  need jq "install jq from the system package manager" jq --version
  need curl "install curl from the system package manager" curl --version
fi

exit "$missing"
