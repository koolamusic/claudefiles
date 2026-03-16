#!/bin/bash
# ---
# name: retro-trigger
# trigger: PostToolUse (Write|Edit|Bash)
# description: >
#   Detects phase completion events and triggers retrospective based on
#   .claude/retrospective.config.json mode (auto/prompt/manual).
#   For GSD projects: watches .planning/STATE.md for phase status → "complete".
#   For git projects: watches for `git tag` commands matching phase patterns.
#   Silent pass-through (exit 0) when no phase completion detected or mode is manual.
# input: Claude Code tool_input JSON on stdin (expects .tool_name, .tool_input)
# exit_codes:
#   0: no phase completion detected or mode is manual — no action
#   2: phase completion detected — message printed to stderr
# timeout: 10
# ---

set -euo pipefail

# Read hook input
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Resolve project root (use CWD from hook input, fall back to pwd)
PROJECT_ROOT="${CWD:-$(pwd)}"
CONFIG_FILE="$PROJECT_ROOT/.claude/retrospective.config.json"

# Bail early if no config exists (skill not initialized)
[[ -f "$CONFIG_FILE" ]] || exit 0

# Read config
ENABLED=$(jq -r '.enabled // true' "$CONFIG_FILE")
MODE=$(jq -r '.mode // "manual"' "$CONFIG_FILE")

# Bail if disabled or manual mode (hook is a no-op in manual)
[[ "$ENABLED" == "true" ]] || exit 0
[[ "$MODE" != "manual" ]] || exit 0

# --- GSD Detection: STATE.md was edited ---
if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

  # Only care about STATE.md
  [[ "$FILE_PATH" == *".planning/STATE.md" ]] || exit 0

  # Check if GSD provider is enabled
  GSD_ENABLED=$(jq -r '.data_sources.providers.gsd.enabled // false' "$CONFIG_FILE")
  [[ "$GSD_ENABLED" == "true" ]] || exit 0

  # Read STATE.md for phase completion signal
  if [[ -f "$FILE_PATH" ]]; then
    # Look for completion markers: "status: complete", "✓ complete", "COMPLETE"
    if grep -qiE '(status[:\s]*complete|✓.*complete|phase.*complete)' "$FILE_PATH" 2>/dev/null; then
      # Extract phase info if possible
      PHASE_NUM=$(grep -oE 'phase[:\s]*[0-9]+' "$FILE_PATH" 2>/dev/null | grep -oE '[0-9]+' | tail -1 || echo "?")
      PHASE_NAME=$(grep -oE 'name[:\s]*.*' "$FILE_PATH" 2>/dev/null | sed 's/name[: ]*//' | head -1 || echo "")

      if [[ "$MODE" == "auto" ]]; then
        cat >&2 <<MSG
[retro] Phase ${PHASE_NUM} complete. Auto-generating retrospective...
Run: /retro ${PHASE_NUM}
MSG
        exit 2
      elif [[ "$MODE" == "prompt" ]]; then
        cat >&2 <<MSG
[retro] Phase ${PHASE_NUM}${PHASE_NAME:+: $PHASE_NAME} is complete. Write the retrospective now?
→ Run /retro to generate
→ Or defer — you'll be reminded next session
MSG
        # Store pending retro
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        jq --arg phase "$PHASE_NUM" \
           --arg name "$PHASE_NAME" \
           --arg ts "$TIMESTAMP" \
           '.pending_retro = {"phase": ($phase | tonumber), "phase_name": $name, "deferred_at": $ts}' \
           "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        exit 2
      fi
    fi
  fi
  exit 0
fi

# --- Git Tag Detection: `git tag` command was run ---
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  # Check if this was a git tag creation command (not listing, deleting, or verifying)
  # Handles: git tag v1.0, git tag -a v1.0 -m "msg", git tag -s v1.0, git tag -am "msg" v1.0
  if echo "$COMMAND" | grep -qE '^git\s+tag\s+' && \
     ! echo "$COMMAND" | grep -qE '^git\s+tag\s+(-l|-d|-v|--list|--delete|--verify)'; then
    # Check if git provider is enabled
    GIT_ENABLED=$(jq -r '.data_sources.providers.git.enabled // false' "$CONFIG_FILE")
    [[ "$GIT_ENABLED" == "true" ]] || exit 0

    # Extract tag name: skip flags (-a, -s, -m "msg", -f, etc.) to find the actual tag name
    TAG_NAME=$(echo "$COMMAND" | sed 's/^git\s\+tag\s\+//' | sed 's/-[asfm]\s\+//g' | sed 's/-m\s\+"[^"]*"\s*//g' | sed "s/-m\s\+'[^']*'\s*//g" | awk '{print $1}')

    if [[ "$MODE" == "auto" ]]; then
      cat >&2 <<MSG
[retro] New tag '${TAG_NAME}' created. Auto-generating retrospective...
Run: /retro
MSG
      exit 2
    elif [[ "$MODE" == "prompt" ]]; then
      cat >&2 <<MSG
[retro] New tag '${TAG_NAME}' created. Write a retrospective for this release?
→ Run /retro to generate
MSG
      exit 2
    fi
  fi
  exit 0
fi

exit 0
