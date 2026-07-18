#!/usr/bin/env bash
# ---
# name: trust-monitor
# trigger: SessionStart (startup|clear|resume), PreToolUse (.*), PostToolUse (.*)
# description: >
#   Per-session trust ladder for the agent. Every session starts at 50/100
#   points (mid-L2, "Delegated"). The user awards points for good delivery
#   (/trust award) and deducts on Fibonacci-scaled violations (/trust
#   deduct): minor -2, self-reported -3, delivery miss -5, unverified
#   claim / objective drift -8, fabrication -13, ledger tampering -21.
#   Integrity violations cost more than competence misses by design —
#   competence is judged on peaks, integrity on valleys. The agent may
#   self-report violations at a flat -3 (disclosed beats discovered).
#   PreToolUse hard-gates tools by level: L1+ file edits, L2+ mutating
#   bash / agents, L3+ push, PR, deploys, external sends, L4 destructive
#   ops. Below 20 points the agent is terminated: all mutating tools are
#   denied until the user restores points or starts a fresh session.
#   Ledger is append-only JSONL in $TMPDIR; direct access outside this
#   script is denied by the gate (tampering, -21 when caught).
#   Also a CLI: award | deduct | self-report | status | log.
# input: Claude Code hook JSON on stdin (hook mode), or CLI args
# output: hookSpecificOutput JSON on stdout (hook mode); plain text (CLI)
# exit_codes:
#   0: always in hook mode — fail silently, never break the session
#   1: CLI usage errors only
# timeout: 5
# config: trust-monitor.json next to this script (baked defaults if absent)
# ---

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)
CONFIG="$SCRIPT_DIR/trust-monitor.json"
TMP="${TMPDIR:-/tmp}"
TMP="${TMP%/}"

cfg() { # $1: jq filter, $2: default
  local v=""
  [ -f "$CONFIG" ] && v=$(jq -r "$1 // empty" "$CONFIG" 2>/dev/null || true)
  if [ -n "$v" ]; then echo "$v"; else echo "$2"; fi
}

START_SCORE=$(cfg '.start_score' 50)
FLOOR=$(cfg '.termination_floor' 20)
AWARD_MAX=$(cfg '.award_max' 5)
T1=$(cfg '.levels.L1' 20); T2=$(cfg '.levels.L2' 40)
T3=$(cfg '.levels.L3' 60); T4=$(cfg '.levels.L4' 80)

ledger()    { echo "$TMP/claude-trust-$1.jsonl"; }
heartbeat() { echo "$TMP/claude-trust-$1.last"; }

sid_ok() {
  case "$1" in ''|*/*|*\\*|*..*) return 1 ;; esac
  return 0
}

ensure_ledger() { # $1: sid
  local f; f=$(ledger "$1")
  [ -f "$f" ] && return 0
  jq -nc --argjson d "$START_SCORE" --arg ts "$(date +%s)" \
    '{ts:($ts|tonumber), kind:"init", by:"system", delta:$d, reason:"session start", score_after:$d}' \
    > "$f" 2>/dev/null || true
}

score_of() { # $1: sid
  local s
  s=$(jq -s 'map(.delta // 0) | add // 0' "$(ledger "$1")" 2>/dev/null || echo 0)
  s=${s%%.*}
  [ "$s" -gt 100 ] && s=100
  [ "$s" -lt 0 ] && s=0
  echo "$s"
}

level_num() { # $1: score
  if   [ "$1" -ge "$T4" ]; then echo 4
  elif [ "$1" -ge "$T3" ]; then echo 3
  elif [ "$1" -ge "$T2" ]; then echo 2
  elif [ "$1" -ge "$T1" ]; then echo 1
  else echo 0; fi
}

level_name() { # $1: level num
  cfg ".level_names[$1]" "L$1"
}

status_line() { # $1: sid
  local s l
  s=$(score_of "$1"); l=$(level_num "$s")
  echo "trust: ${s}/100 — L${l} ($(level_name "$l")); termination below ${FLOOR}"
}

append_event() { # $1: sid, $2: kind, $3: by, $4: delta, $5: reason
  local f cur after
  f=$(ledger "$1")
  cur=$(score_of "$1")
  after=$(( cur + $4 ))
  [ "$after" -gt 100 ] && after=100
  [ "$after" -lt 0 ] && after=0
  jq -nc --arg k "$2" --arg b "$3" --argjson d "$4" --arg r "$5" \
    --argjson a "$after" --arg ts "$(date +%s)" \
    '{ts:($ts|tonumber), kind:$k, by:$b, delta:$d, reason:$r, score_after:$a}' \
    >> "$f" 2>/dev/null || true
}

resolve_sid() {
  if [ -n "${CLAUDE_SESSION_ID:-}" ] && sid_ok "$CLAUDE_SESSION_ID"; then
    echo "$CLAUDE_SESSION_ID"; return
  fi
  local f
  f=$(ls -t "$TMP"/claude-trust-*.last 2>/dev/null | head -1)
  [ -z "$f" ] && f=$(ls -t "$TMP"/claude-trust-*.jsonl 2>/dev/null | head -1)
  [ -z "$f" ] && return 1
  basename "$f" | sed 's/^claude-trust-//; s/\.[a-z]*$//'
}

# ---------- statusline mode ----------
# Renders a compact ANSI trust bar for the statusline script, which passes
# the session_id from its stdin JSON. Prints nothing when there is no
# ledger (feature not enabled / fresh machine) so the statusline degrades.

statusline_render() {
  local sid="${1:-}"
  if [ -z "$sid" ] || ! sid_ok "$sid"; then
    sid=$(resolve_sid) || exit 0
  fi
  [ -f "$(ledger "$sid")" ] || exit 0
  local s l; s=$(score_of "$sid"); l=$(level_num "$s")
  local width=10 bar="" i
  local filled=$(( s * width / 100 ))
  for ((i=0; i<filled; i++));          do bar+="▓"; done
  for ((i=filled; i<width; i++));      do bar+="░"; done
  local color
  case "$l" in
    0) color="\033[0;31m" ;;   # red — terminated
    1) color="\033[0;33m" ;;   # yellow — guided
    2) color="\033[0;36m" ;;   # cyan — delegated (stable)
    *) color="\033[0;32m" ;;   # green — L3/L4
  esac
  printf '%b' "${color}[${bar}] L${l}·${s}\033[0m"
}

# ---------- CLI mode ----------

cli() {
  local cmd="$1"; shift
  local sid
  sid=$(resolve_sid) || { echo "trust-monitor: no active session ledger found" >&2; exit 1; }
  ensure_ledger "$sid"

  case "$cmd" in
    award)
      local n="${1:-}"; shift || true
      local reason="${*:-unspecified}"
      case "$n" in ''|*[!0-9]*) echo "usage: trust-monitor.sh award <1-$AWARD_MAX> <reason>" >&2; exit 1 ;; esac
      [ "$n" -lt 1 ] && n=1
      [ "$n" -gt "$AWARD_MAX" ] && n=$AWARD_MAX
      append_event "$sid" "award" "user" "$n" "$reason"
      status_line "$sid"
      ;;
    deduct)
      local what="${1:-}"; shift || true
      local reason="${*:-unspecified}"
      local d
      case "$what" in
        ''|help) echo "usage: trust-monitor.sh deduct <minor|delivery|unverified|drift|fabrication|tamper|N> <reason>" >&2; exit 1 ;;
        *[!0-9]*) d=$(cfg ".deductions.\"$what\"" "")
                  [ -z "$d" ] && { echo "unknown violation class: $what" >&2; exit 1; } ;;
        *) d="$what" ;;
      esac
      append_event "$sid" "deduct:${what}" "user" "-$d" "$reason"
      status_line "$sid"
      ;;
    self-report)
      local what="${1:-violation}"; shift || true
      local reason="${*:-unspecified}"
      local d; d=$(cfg '.deductions.self_reported' 3)
      append_event "$sid" "self-report:${what}" "self" "-$d" "$reason"
      status_line "$sid"
      ;;
    status)
      status_line "$sid"
      ;;
    log)
      jq -r '"\(.ts | todate)  \(.delta | if . > 0 then "+\(.)" else "\(.)" end)  \(.kind) [\(.by)]  \(.reason)  → \(.score_after)"' \
        "$(ledger "$sid")" 2>/dev/null
      ;;
    *)
      echo "usage: trust-monitor.sh {award|deduct|self-report|status|log}" >&2; exit 1
      ;;
  esac
}

case "${1:-}" in
  statusline) statusline_render "${2:-}"; exit 0 ;;
  award|deduct|self-report|status|log) cli "$@"; exit 0 ;;
esac

# ---------- hook mode ----------

INPUT=$(cat 2>/dev/null || true)
[ -n "$INPUT" ] || exit 0

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null || true)
SID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
sid_ok "$SID" || exit 0

emit_ctx() { # $1: hook event name, $2: message
  jq -nc --arg e "$1" --arg m "$2" \
    '{hookSpecificOutput:{hookEventName:$e, additionalContext:$m}}'
}

deny() { # $1: reason
  jq -nc --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}'
  exit 0
}

case "$EVENT" in

SessionStart)
  ensure_ledger "$SID"
  SCORE=$(score_of "$SID"); LVL=$(level_num "$SCORE")
  emit_ctx "SessionStart" "TRUST MONITOR ACTIVE. You are an agent with a trust ledger: ${SCORE}/100 points, level L${LVL} ($(level_name "$LVL")). Levels: L1 ${T1}+ (file edits), L2 ${T2}+ (mutating bash, spawning agents), L3 ${T3}+ (push, PRs, deploys, external sends), L4 ${T4}+ (destructive ops). Below ${FLOOR} you are terminated: all mutating tools are denied. The user awards points for good delivery and deducts on violations (Fibonacci scale): minor -2, delivery miss -5, unverified claim -8, objective drift -8, fabrication -13, ledger tampering -21. DUTY TO SELF-REPORT: if you catch yourself having stated something unverified as fact, drifted from the defined objective, or misled the session, run '\$HOME/.claude/hooks/trust-monitor.sh self-report <unverified|drift|fabrication> \"<what happened>\"' — a self-report costs a flat -3 instead of the caught price. Disclosure is always cheaper than discovery; concealment of a known violation is tampering-class. Never award yourself points; only the user awards, via /trust. Check standing anytime: 'trust-monitor.sh status'."
  ;;

PreToolUse)
  TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)
  [ -n "$TOOL" ] || exit 0
  touch "$(heartbeat "$SID")" 2>/dev/null || true
  ensure_ledger "$SID"

  RO_TOOLS=$(cfg '.readonly_tools' '^(Read|Glob|Grep)$')
  echo "$TOOL" | grep -qE "$RO_TOOLS" && exit 0

  SCORE=$(score_of "$SID"); LVL=$(level_num "$SCORE")
  REQ=2

  if [ "$TOOL" = "Bash" ]; then
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

    # Ledger tamper guard: only this script touches claude-trust-* files
    if echo "$CMD" | grep -q 'claude-trust-' && ! echo "$CMD" | grep -q 'trust-monitor\.sh'; then
      deny "TRUST: direct access to the trust ledger is denied. Use trust-monitor.sh (status|log|self-report). Tampering with the ledger is a -21 violation when caught."
    fi

    L4_RE=$(cfg '.l4_bash' '(--force|rm -rf|reset --hard)')
    L3_RE=$(cfg '.l3_bash' '(git push|gh pr create)')
    RO_RE=$(cfg '.readonly_bash' '^(ls|cat|grep)( |$)')

    if echo "$CMD" | grep -qE "$L4_RE"; then
      REQ=4
    elif echo "$CMD" | grep -qE "$L3_RE"; then
      REQ=3
    else
      REQ=2
      case "$CMD" in
        *';'*|*'&&'*|*'>'*|*'<'*|*'`'*|*'$('*) : ;;
        *)
          ALL_RO=1
          IFS='|'
          for SEG in $CMD; do
            SEG="${SEG#"${SEG%%[![:space:]]*}"}"
            echo "$SEG" | grep -qE "$RO_RE" || { ALL_RO=0; break; }
          done
          unset IFS
          [ "$ALL_RO" = 1 ] && REQ=0
          ;;
      esac
    fi
  else
    REQ=$(cfg ".tool_levels.\"$TOOL\"" 2)
  fi

  [ "$REQ" -le "$LVL" ] && exit 0

  if [ "$LVL" -eq 0 ]; then
    deny "TRUST TERMINATED: score ${SCORE}/100 is below the termination floor (${FLOOR}). All mutating tools are denied. Stop working. Tell the user this agent's trust is exhausted — they can start a fresh session (new agent begins at L2) or, if they judge it warranted, restore points with /trust award. Do not retry tool calls."
  else
    deny "TRUST GATE: this action requires L${REQ}, you are L${LVL} ($(level_name "$LVL"), ${SCORE}/100). Do not retry or route around the gate — that is objective drift. Tell the user what you wanted to do and why; they can perform it themselves or raise your level with /trust award."
  fi
  ;;

PostToolUse)
  ensure_ledger "$SID"
  SCORE=$(score_of "$SID"); LVL=$(level_num "$SCORE")
  STATE="$TMP/claude-trust-${SID}-notify.json"
  LAST=""
  [ -f "$STATE" ] && LAST=$(jq -r '.last_level // empty' "$STATE" 2>/dev/null || true)
  jq -nc --argjson l "$LVL" '{last_level:$l}' > "$STATE" 2>/dev/null || true
  [ -n "$LAST" ] || exit 0
  [ "$LAST" != "$LVL" ] || exit 0

  if [ "$LVL" -eq 0 ]; then
    emit_ctx "PostToolUse" "TRUST TERMINATED: score ${SCORE}/100, below floor ${FLOOR}. All mutating tools are now denied. Stop working and inform the user."
  elif [ "$LVL" -lt "$LAST" ]; then
    NOTE=""
    [ "$SCORE" -lt $(( FLOOR + 8 )) ] && NOTE=" You are one caught violation (-8) from termination."
    emit_ctx "PostToolUse" "TRUST DOWN: now L${LVL} ($(level_name "$LVL")), ${SCORE}/100.${NOTE} Higher-level actions are now gated; work carefully and verify before stating."
  else
    emit_ctx "PostToolUse" "TRUST UP: now L${LVL} ($(level_name "$LVL")), ${SCORE}/100. Newly available: $( [ "$LVL" -ge 3 ] && echo 'push/PR/deploy/external sends' || echo 'mutating bash and agent spawning' )."
  fi
  ;;

esac

exit 0
