#!/bin/bash
# ---
# name: shaping-ripple
# trigger: PostToolUse (Write|Edit)
# description: >
#   Ripple-check reminder for shaping documents. When a file with
#   `shaping: true` frontmatter is edited, prints a checklist to stderr
#   reminding the author to keep related sections in sync (tables before
#   Mermaid, requirements → fit check, parts → gaps, work streams).
#   Silent pass-through (exit 0) for all non-shaping files.
# input: Claude Code tool_input JSON on stdin (expects .tool_input.file_path)
# exit_codes:
#   0: file is not a shaping doc — no action
#   2: shaping doc detected — reminder printed to stderr
# timeout: 5
# ---
FILE=$(jq -r '.tool_input.file_path // empty')
if [[ "$FILE" == *.md && -f "$FILE" ]]; then
  if head -5 "$FILE" 2>/dev/null | grep -q '^shaping: true'; then
    cat >&2 <<'MSG'
Ripple check:
- Updated a Breadboard diagram? → Affordance tables are the source of truth. Update tables FIRST, then render to Mermaid
- Changed Requirements? → update Fit Check + any Gaps, Open Questions by Part
- Changed Shape (A, B...) Parts? → update Fit Check + any Gaps, Open Questions by Part
- Changed Work Streams Detail? → update Work Streams Mermaid
MSG
    exit 2
  fi
fi
exit 0
