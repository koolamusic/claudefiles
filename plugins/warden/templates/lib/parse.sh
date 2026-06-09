#!/usr/bin/env bash
# .warden/lib/parse.sh - parse WARDEN_RESULT lines from a log
#
# Counts lines that begin with `WARDEN_RESULT <kind> ` (note the trailing
# space; this prevents `WARDEN_RESULT passed-validation` from matching).

warden_count_results() {
  local log="$1"
  local kind="$2"
  local count=0
  if [[ -f "$log" ]]; then
    count=$(grep -c "^WARDEN_RESULT ${kind} " "$log" 2>/dev/null) || count=0
  fi
  echo "$count"
}
