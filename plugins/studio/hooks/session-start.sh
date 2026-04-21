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

# Read expected symlinks from .workspacerc. Projects declare only what they
# actually use — e.g. a project with no jira sprint work omits ".jira" from
# this list so the hook doesn't flag its absence as drift. Partial adoption
# is a first-class state.
SYMLINKS=$(jq -r '.symlinks // [] | .[]' "$WORKSPACERC" 2>/dev/null)

# Back-compat: if .workspacerc has no symlinks field, treat as zero expected
# symlinks (no drift reported). Re-run /studio:setup to populate the field.
if [[ -z "$SYMLINKS" ]]; then
  echo "[studio] workspace ok: $WORKSPACE (no symlinks declared in .workspacerc)" >&2
  exit 0
fi

MISSING=0
DRIFT=0

while IFS= read -r name; do
  [[ -z "$name" ]] && continue
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
done <<< "$SYMLINKS"

if [[ "$MISSING" -eq 0 && "$DRIFT" -eq 0 ]]; then
  echo "[studio] workspace ok: $WORKSPACE" >&2
else
  echo "[studio] workspace drift: missing=$MISSING drift=$DRIFT (workspace=$WORKSPACE)" >&2
fi

exit 0
