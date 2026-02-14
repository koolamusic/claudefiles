#!/usr/bin/env bash
set -euo pipefail

# claudefiles bootstrap — clone the repo, then let Claude do the rest
REPO="https://github.com/koolamusic/claudefiles.git"
TARGET="${CLAUDEFILES_DIR:-$HOME/.claudefiles}"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}claudefiles${NC} — portable Claude Code configuration"
echo ""

# Check for git
if ! command -v git &>/dev/null; then
  echo "Error: git is required but not installed."
  exit 1
fi

# Clone or update
if [ -d "$TARGET/.git" ]; then
  echo "Updating existing claudefiles at $TARGET..."
  git -C "$TARGET" pull --ff-only
else
  if [ -d "$TARGET" ]; then
    echo "Error: $TARGET exists but is not a git repo. Remove it first or set CLAUDEFILES_DIR."
    exit 1
  fi
  echo "Cloning claudefiles to $TARGET..."
  git clone "$REPO" "$TARGET"
fi

echo ""
echo -e "${GREEN}✓${NC} Claudefiles ready at ${CYAN}$TARGET${NC}"
echo ""
echo "Now run Claude to complete setup:"
echo ""
echo "  cd $TARGET && claude \"/setup\""
echo ""
