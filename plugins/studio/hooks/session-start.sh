#!/bin/bash
# ---
# name: studio-session-start
# trigger: SessionStart (startup)
# description: >
#   Reads .workspacerc in the project root, validates each symlink resolves
#   into the workspace slug dir, emits a one-line status to stderr, always exits 0.
# input: none (runs at session start)
# exit_codes:
#   0: always
# ---
# Note: caller must set exec permissions (chmod +x) when copying into the workspace.

set -euo pipefail

PROJECT_ROOT="$(pwd)"
WORKSPACERC="${PROJECT_ROOT}/.workspacerc"

[[ -f "$WORKSPACERC" ]] || exit 0

WORKSPACE_RAW=$(jq -r '.workspace // empty' "$WORKSPACERC")
if [[ -z "$WORKSPACE_RAW" ]]; then
  echo "[studio] .workspacerc present but workspace field missing or empty" >&2
  exit 0
fi

WORKSPACE="${WORKSPACE_RAW/#\~/$HOME}"

if [[ ! -d "$WORKSPACE" ]]; then
  echo "[studio] workspace dir not found: $WORKSPACE" >&2
  exit 0
fi

MISSING=0
DRIFT=0

for name in .jira .planning .retrospective .uat; do
  link_path="$PROJECT_ROOT/$name"
  if [[ ! -L "$link_path" ]]; then
    MISSING=$((MISSING + 1))
  else
    target=$(readlink "$link_path")
    # Expand relative targets against project root for comparison
    case "$target" in
      /*) resolved="$target" ;;
      *) resolved="$PROJECT_ROOT/$target" ;;
    esac
    if [[ "$resolved" != "$WORKSPACE"* ]]; then
      DRIFT=$((DRIFT + 1))
    fi
  fi
done

if [[ "$MISSING" -eq 0 && "$DRIFT" -eq 0 ]]; then
  echo "[studio] workspace ok: $WORKSPACE" >&2
else
  echo "[studio] workspace drift: missing=$MISSING drift=$DRIFT (workspace=$WORKSPACE)" >&2
fi

exit 0
