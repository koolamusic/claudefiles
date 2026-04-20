#!/usr/bin/env bash
# ---
# name: context-monitor
# trigger: PostToolUse (.*)
# description: >
#   Warns the agent when context usage is high. Reads the last assistant
#   message's `usage` block from the session's transcript_path, computes
#   used/remaining percentage against the context window, and emits
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
CRITICAL_THRESHOLD=25
DEBOUNCE_CALLS=5
DEFAULT_WINDOW=200000

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

# Pull the last assistant message's usage block. JSONL; one line per event.
LAST_USAGE=$(jq -c 'select(.type == "assistant") | .message.usage // empty' \
  "$TRANSCRIPT_PATH" 2>/dev/null | tail -1)
[ -n "$LAST_USAGE" ] || exit 0

# Token counts (cache read + cache create + input — output tokens don't consume context window)
INPUT_TOKENS=$(echo "$LAST_USAGE"  | jq -r '.input_tokens // 0'                 2>/dev/null || echo 0)
CACHE_READ=$(echo "$LAST_USAGE"    | jq -r '.cache_read_input_tokens // 0'      2>/dev/null || echo 0)
CACHE_CREATE=$(echo "$LAST_USAGE"  | jq -r '.cache_creation_input_tokens // 0'  2>/dev/null || echo 0)
TOTAL=$(( INPUT_TOKENS + CACHE_READ + CACHE_CREATE ))
[ "$TOTAL" -gt 0 ] || exit 0

# Window: env override, else default. If used already exceeds 200k, bump to 1M (heuristic for [1m] sessions).
WINDOW="${CLAUDE_CONTEXT_WINDOW:-$DEFAULT_WINDOW}"
if [ "$TOTAL" -gt "$DEFAULT_WINDOW" ] && [ "$WINDOW" -le "$DEFAULT_WINDOW" ]; then
  WINDOW=1000000
fi

USED_PCT=$(( (TOTAL * 100) / WINDOW ))
REMAINING_PCT=$(( 100 - USED_PCT ))

# Above warning threshold — nothing to do
[ "$REMAINING_PCT" -le "$WARNING_THRESHOLD" ] || exit 0

# Debounce state
TMP="${TMPDIR:-/tmp}"
TMP="${TMP%/}"
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
    MSG="CONTEXT CRITICAL: usage ${USED_PCT}%, remaining ${REMAINING_PCT}%. A .jira/ sprint is active — do NOT start new waves or plans. Tell the user to run /jira:retro at the next natural stopping point so the sprint is checkpointed before context exhausts. STATE.md already tracks the sprint; no handoff file needed."
  else
    MSG="CONTEXT CRITICAL: usage ${USED_PCT}%, remaining ${REMAINING_PCT}%. Context is nearly exhausted. Inform the user and ask how they want to proceed. Do NOT autonomously save state or write handoff files unless the user asks."
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
