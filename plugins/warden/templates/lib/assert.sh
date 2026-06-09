#!/usr/bin/env bash
# .warden/lib/assert.sh - assertion primitives for warden plans
#
# Plans `source "$WARDEN_LIB/assert.sh"` at the top of their bash block.
# Each assertion emits two lines:
#   1. A human-readable line for log readers
#   2. A `WARDEN_RESULT <kind> <id>` line that the runner counts
#
# The structured line is the canonical signal. Any plan output that happens
# to contain phrases like "items passed validation" is ignored by the runner
# because it does not start with `WARDEN_RESULT`.

: "${WARDEN_PASS:=0}"
: "${WARDEN_FAIL:=0}"
: "${WARDEN_SKIP:=0}"

warden_pass() {
  local id="$1"
  local msg="${2:-}"
  WARDEN_PASS=$((WARDEN_PASS + 1))
  if [[ -n "$msg" ]]; then
    echo "  ok  $id: $msg"
    echo "WARDEN_RESULT pass $id $msg"
  else
    echo "  ok  $id"
    echo "WARDEN_RESULT pass $id"
  fi
}

warden_fail() {
  local id="$1"
  local msg="${2:-}"
  WARDEN_FAIL=$((WARDEN_FAIL + 1))
  if [[ -n "$msg" ]]; then
    echo "  FAIL $id: $msg"
    echo "WARDEN_RESULT fail $id $msg"
  else
    echo "  FAIL $id"
    echo "WARDEN_RESULT fail $id"
  fi
}

warden_skip() {
  local id="$1"
  local msg="${2:-}"
  WARDEN_SKIP=$((WARDEN_SKIP + 1))
  if [[ -n "$msg" ]]; then
    echo "  skip $id: $msg"
    echo "WARDEN_RESULT skip $id $msg"
  else
    echo "  skip $id"
    echo "WARDEN_RESULT skip $id"
  fi
}

# Optional helper for plans that want to print a summary footer
warden_summary() {
  echo ""
  echo "$WARDEN_PASS passed, $WARDEN_FAIL failed, $WARDEN_SKIP skipped"
}
