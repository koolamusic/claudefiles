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

YELLOW='\033[0;33m'
RED='\033[0;31m'

# Check required dependencies
MISSING=0
for cmd in git jq claude; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}Error:${NC} $cmd is required but not installed."
    MISSING=1
  fi
done
[ $MISSING -eq 1 ] && exit 1

# Check optional dependencies
if ! command -v gh &>/dev/null; then
  echo -e "${YELLOW}Note:${NC} gh (GitHub CLI) not found — preview-markdown.sh won't work without it."
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
