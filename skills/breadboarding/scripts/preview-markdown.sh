#!/bin/bash
# ---
# name: preview-markdown
# description: >
#   Render a markdown file through GitHub's markdown API (same renderer
#   as github.com) and check for broken tables, unclosed code blocks,
#   and unrendered Mermaid keywords. Useful for validating breadboarding
#   and shaping SKILL.md files before committing.
# usage: ./preview-markdown.sh [file] [--open]
# dependencies: gh (GitHub CLI), jq
# output: .gfm-preview.html in the current directory
# ---

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FILE="${1:-$SCRIPT_DIR/SKILL.md}"
OPEN=false
for arg in "$@"; do [[ "$arg" == "--open" ]] && OPEN=true; done

echo "Rendering $FILE through GitHub markdown API..."

# GitHub's API accepts raw markdown via POST /markdown
BODY=$(jq -n --arg text "$(cat "$FILE")" '{text: $text, mode: "gfm"}')

gh api /markdown \
  --method POST \
  --input - <<< "$BODY" \
  > .gfm-preview.html 2>/tmp/gfm-error.txt

if [ $? -ne 0 ]; then
  echo "API error:"
  cat /tmp/gfm-error.txt
  exit 1
fi

# Count potential issues: broken tables, raw HTML errors, etc.
LINES=$(wc -l < .gfm-preview.html | tr -d ' ')
echo "Rendered $LINES lines of HTML → .gfm-preview.html"

# Check for signs of broken rendering
BROKEN_PIPES=$(grep -c '|' .gfm-preview.html || true)
RAW_BACKTICKS=$(grep -c '```' .gfm-preview.html || true)
RAW_MERMAID=$(grep -c 'flowchart\|subgraph' .gfm-preview.html || true)

echo ""
echo "Quick checks:"
echo "  Raw pipe chars (possible broken tables): $BROKEN_PIPES"
echo "  Raw backticks (unclosed code blocks):    $RAW_BACKTICKS"
echo "  Raw mermaid keywords (unrendered):       $RAW_MERMAID"

if $OPEN; then
  open .gfm-preview.html
fi
