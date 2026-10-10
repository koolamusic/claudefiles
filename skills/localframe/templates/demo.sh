#!/usr/bin/env bash
# Terminal shot list. Copy into the take directory, edit the scenes, dry-run with
#   bash demo.sh
# until every command and jq filter works against the real API, then record it.
set -uo pipefail

PROMPT=$'\e[1;32m$\e[0m '
TYPE_DELAY=0.03

type_line() { printf '%s' "$PROMPT"; for ((i = 0; i < ${#1}; i++)); do printf '%s' "${1:i:1}"; sleep "$TYPE_DELAY"; done; echo; }
run() { type_line "$1"; sleep 2; eval "$1"; sleep 4; }
comment() { printf '\e[2m# %s\e[0m\n' "$1"; sleep 2; }

# Secrets come from the take's scratch file, never from an argument or this script.
# Commands reference them as \$DEMO_KEY, so the typed line shows the name, not the value.
# shellcheck source=/dev/null
[ -f .take/secrets.env ] && . .take/secrets.env
: "${BASE_URL:?set BASE_URL in .take/secrets.env or the environment}"

clear

comment "Check the service is up"
run "curl -s \$BASE_URL/health | jq ."

# comment "List projects with the demo key"
# run "curl -s -H \"Authorization: Bearer \$DEMO_KEY\" \$BASE_URL/v1/projects | jq '.data[] | {id, name}'"

sleep 2
