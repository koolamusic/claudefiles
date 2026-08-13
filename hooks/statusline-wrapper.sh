#!/usr/bin/env bash
# ---
# name: statusline-wrapper
# trigger: statusLine (settings.json "statusLine" command)
# description: >
#   Statusline composer that appends the trust-monitor bar to the base
#   statusline. Delegates the base line to gsd-statusline.js when present
#   (GSD installs it), otherwise renders a minimal "model | dir | ctx%"
#   line. Then appends 'trust-monitor.sh statusline <session_id>' — which
#   prints nothing when no trust ledger exists, so the line degrades
#   cleanly with the trust-monitor feature disabled.
# input: Claude Code statusline JSON on stdin
# output: single statusline string on stdout
# ---

INPUT=$(cat)

GSD="$HOME/.claude/hooks/gsd-statusline.js"
if [ -f "$GSD" ] && command -v node >/dev/null 2>&1; then
  LINE=$(echo "$INPUT" | node "$GSD")
else
  MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"' 2>/dev/null)
  DIR=$(echo "$INPUT" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
  REMAINING=$(echo "$INPUT" | jq -r '.context_window.remaining_percentage // empty' 2>/dev/null)
  LINE=$(printf '\033[2m%s\033[0m │ \033[2m%s\033[0m' "$MODEL" "$(basename "${DIR:-?}")")
  if [ -n "$REMAINING" ]; then
    USED=$(( 100 - ${REMAINING%%.*} ))
    LINE="$LINE $(printf '\033[32m%s%%\033[0m' "$USED")"
  fi
fi

SID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TRUST=$("$HOME/.claude/hooks/trust-monitor.sh" statusline "$SID" 2>/dev/null)

if [ -n "$TRUST" ]; then
  printf '%s │ %s' "$LINE" "$TRUST"
else
  printf '%s' "$LINE"
fi
