#!/usr/bin/env bash
# ---
# name: context-monitor
# trigger: PostToolUse (.*)
# description: >
#   Warns the agent when context usage is high. Preferred source: the
#   statusline bridge file ($TMPDIR/claude-ctxwin-<session_id>.json, written
#   by statusline-command.sh) — the statusline is the only script Claude
#   Code hands the session's real context_window, so this is exact for both
#   200k and 1M sessions. Fallback: compute from the last assistant
#   message's `usage` block in transcript_path against an inferred window
#   (env override → `[1m]` in model id → 200k default). Emits
#   additionalContext on thresholds. Debounces to avoid spam. Jira-aware:
#   different CRITICAL/WARNING copy when .jira/STATE.md exists — suggests
#   /jira:retro at a natural stopping point so the sprint gets checkpointed.
# input: Claude Code hook JSON on stdin (expects .session_id, .cwd, .transcript_path)
# output: hookSpecificOutput JSON on stdout when a warning fires; otherwise nothing
# exit_codes:
#   0: always — never block tool execution; fail silently on any error
# timeout: 5
# env overrides:
#   CLAUDE_CONTEXT_WINDOW — override context window size (default 200000)
# ---

set -u

WARNING_THRESHOLD=35
CRITICAL_THRESHOLD=20
DEBOUNCE_CALLS=5
DEFAULT_WINDOW=200000
BRIDGE_STALE_SECONDS=60

# Read stdin
INPUT=$(cat 2>/dev/null || true)
[ -n "$INPUT" ] || exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)

[ -n "$SESSION_ID" ] || exit 0
[ -n "$TRANSCRIPT_PATH" ] || exit 0
[ -f "$TRANSCRIPT_PATH" ] || exit 0

# Sanitize session_id (no path traversal — it goes into /tmp filename)
case "$SESSION_ID" in
  */*|*\\*|*..*) exit 0 ;;
esac

TMP="${TMPDIR:-/tmp}"
TMP="${TMP%/}"

# Preferred source: the statusline bridge file. Claude Code hands the
# statusline (and only the statusline) the session's real context_window —
# including the exact window size and pre-computed percentages — and
# statusline-command.sh caches it per-session. Authoritative for both
# 200k and 1M sessions; no window guessing needed.
USED_PCT=""
REMAINING_PCT=""
BRIDGE="$TMP/claude-ctxwin-${SESSION_ID}.json"
if [ -f "$BRIDGE" ]; then
  BRIDGE_TS=$(jq -r '.ts // 0' "$BRIDGE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  if [ $(( NOW - BRIDGE_TS )) -le "$BRIDGE_STALE_SECONDS" ]; then
    REMAINING_PCT=$(jq -r '.context_window.remaining_percentage // empty' "$BRIDGE" 2>/dev/null || true)
    USED_PCT=$(jq -r '.context_window.used_percentage // empty' "$BRIDGE" 2>/dev/null || true)
    REMAINING_PCT=${REMAINING_PCT%%.*}  # floats → ints for shell arithmetic
    USED_PCT=${USED_PCT%%.*}
  fi
fi

# Fallback: compute from the transcript when the bridge is missing or stale
# (fresh session before first statusline render, custom statusline without
# the bridge write, etc.).
if [ -z "$REMAINING_PCT" ] || [ -z "$USED_PCT" ]; then
  # Pull the last assistant message's usage block + model id. JSONL; one line per event.
  LAST_MSG=$(jq -c 'select(.type == "assistant") | select(.message.usage != null) | {u: .message.usage, m: (.message.model // "")}' \
    "$TRANSCRIPT_PATH" 2>/dev/null | tail -1)
  [ -n "$LAST_MSG" ] || exit 0
  LAST_USAGE=$(echo "$LAST_MSG" | jq -c '.u' 2>/dev/null || true)
  MODEL=$(echo "$LAST_MSG" | jq -r '.m' 2>/dev/null || true)
  [ -n "$LAST_USAGE" ] || exit 0

  # Token counts (cache read + cache create + input — output tokens don't consume context window)
  INPUT_TOKENS=$(echo "$LAST_USAGE"  | jq -r '.input_tokens // 0'                 2>/dev/null || echo 0)
  CACHE_READ=$(echo "$LAST_USAGE"    | jq -r '.cache_read_input_tokens // 0'      2>/dev/null || echo 0)
  CACHE_CREATE=$(echo "$LAST_USAGE"  | jq -r '.cache_creation_input_tokens // 0'  2>/dev/null || echo 0)
  TOTAL=$(( INPUT_TOKENS + CACHE_READ + CACHE_CREATE ))
  [ "$TOTAL" -gt 0 ] || exit 0

  # Window: env override wins; else detect 1M sessions from the model id (e.g. claude-opus-4-8[1m]);
  # else default. Last-resort: if used already exceeds the assumed window, bump to 1M.
  WINDOW="${CLAUDE_CONTEXT_WINDOW:-}"
  if [ -z "$WINDOW" ]; then
    case "$MODEL" in
      *"[1m]"*) WINDOW=1000000 ;;
      *)        WINDOW=$DEFAULT_WINDOW ;;
    esac
    if [ "$TOTAL" -gt "$WINDOW" ]; then
      WINDOW=1000000
    fi
  fi

  USED_PCT=$(( (TOTAL * 100) / WINDOW ))
  REMAINING_PCT=$(( 100 - USED_PCT ))
fi

# Above warning threshold — nothing to do
[ "$REMAINING_PCT" -le "$WARNING_THRESHOLD" ] || exit 0

# Debounce state
WARN_PATH="$TMP/claude-ctx-${SESSION_ID}-warned.json"

PREV_CALLS=0
LAST_LEVEL=""
IS_FIRST_WARN="true"
if [ -f "$WARN_PATH" ]; then
  PREV_CALLS=$(jq -r '.calls_since_warn // 0' "$WARN_PATH" 2>/dev/null || echo 0)
  LAST_LEVEL=$(jq -r  '.last_level // ""'      "$WARN_PATH" 2>/dev/null || echo "")
  IS_FIRST_WARN="false"
fi

CALLS=$(( PREV_CALLS + 1 ))

if [ "$REMAINING_PCT" -le "$CRITICAL_THRESHOLD" ]; then
  CURRENT_LEVEL="critical"
else
  CURRENT_LEVEL="warning"
fi

# Severity escalation bypasses debounce
IS_ESCALATION="false"
if [ "$CURRENT_LEVEL" = "critical" ] && [ "$LAST_LEVEL" = "warning" ]; then
  IS_ESCALATION="true"
fi

if [ "$IS_FIRST_WARN" = "false" ] \
   && [ "$CALLS" -lt "$DEBOUNCE_CALLS" ] \
   && [ "$IS_ESCALATION" = "false" ]; then
  # Suppress: just update the counter and exit quietly
  jq -nc --argjson c "$CALLS" --arg l "$LAST_LEVEL" \
    '{calls_since_warn:$c, last_level:$l}' > "$WARN_PATH" 2>/dev/null || true
  exit 0
fi

# We are emitting a warning — reset the counter, record level
jq -nc --arg l "$CURRENT_LEVEL" \
  '{calls_since_warn:0, last_level:$l}' > "$WARN_PATH" 2>/dev/null || true

# Jira-aware copy
JIRA_ACTIVE="false"
if [ -n "$CWD" ] && [ -f "$CWD/.jira/STATE.md" ]; then
  JIRA_ACTIVE="true"
fi

if [ "$CURRENT_LEVEL" = "critical" ]; then
  if [ "$JIRA_ACTIVE" = "true" ]; then
    MSG="CONTEXT CRITICAL: usage ${USED_PCT}%, remaining ${REMAINING_PCT}%. A .jira/ sprint is active — avoid starting new waves or plans. Tell the user to run /jira:retro at the next natural stopping point so the sprint is checkpointed before context exhausts. STATE.md already tracks the sprint; no handoff file needed. If the user has chosen to push on instead, respect that: do not re-offer, continue at full quality. This warning repeats automatically; a repeat is not a reason to ask again."
  else
    MSG="CONTEXT CRITICAL: usage ${USED_PCT}%, remaining ${REMAINING_PCT}%. Context is nearly exhausted. At the next natural stopping point, tell the user you're ready to run /handoff and offer to do it now — you still have full context, so the handoff you write now will be far better than one reconstructed later. If the user has already agreed to this in-session, invoke the handoff skill directly. If the user has DECLINED the handoff or chosen to push on to finish the task, respect that: do not re-offer, do not wind work down — continue at full quality and let them drive. This warning repeats automatically; a repeat is not a reason to ask again."
  fi
else
  if [ "$JIRA_ACTIVE" = "true" ]; then
    MSG="CONTEXT WARNING: usage ${USED_PCT}%, remaining ${REMAINING_PCT}%. A .jira/ sprint is active — avoid starting new waves. If you're between waves, this is a natural pause point; inform the user."
  else
    MSG="CONTEXT WARNING: usage ${USED_PCT}%, remaining ${REMAINING_PCT}%. Be aware that context is getting limited. Avoid unnecessary exploration or starting new complex work."
  fi
fi

jq -nc --arg msg "$MSG" \
  '{hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$msg}}'

exit 0
