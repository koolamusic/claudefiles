#!/bin/bash
# ---
# name: retro-reminder
# trigger: SessionStart
# description: >
#   Checks for pending retrospectives on session start. If
#   .claude/retrospective.config.json has a non-null pending_retro,
#   prints a reminder to stderr. Silent exit 0 if no pending retro.
# input: Claude Code session JSON on stdin (expects .cwd)
# exit_codes:
#   0: no pending retro — no action
#   2: pending retro found — reminder printed to stderr
# timeout: 5
# ---

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
PROJECT_ROOT="${CWD:-$(pwd)}"
CONFIG_FILE="$PROJECT_ROOT/.claude/retrospective.config.json"

# Bail if no config
[[ -f "$CONFIG_FILE" ]] || exit 0

# Check for pending retro
PENDING=$(jq -r '.pending_retro // empty' "$CONFIG_FILE")
[[ -n "$PENDING" && "$PENDING" != "null" ]] || exit 0

PHASE=$(echo "$PENDING" | jq -r '.phase // "?"')
PHASE_NAME=$(echo "$PENDING" | jq -r '.phase_name // ""')
DEFERRED_AT=$(echo "$PENDING" | jq -r '.deferred_at // ""')

cat >&2 <<MSG
[retro] Pending retrospective: Phase ${PHASE}${PHASE_NAME:+: $PHASE_NAME}
  Deferred: ${DEFERRED_AT}
  → Run /retro to generate now
MSG
exit 2
