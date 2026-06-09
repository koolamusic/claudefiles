#!/usr/bin/env bash
# .warden/lib/audit.sh - structured audit trail across runs
#
# Three append-only artifacts live under .warden/runs/:
#   - asserts.jsonl       every assertion across all runs ever
#   - observations.jsonl  every observation (data point, not pass/fail)
#   - state               current key=value state (last write per key wins)
#
# These survive run boundaries by design. /warden:report reads them to
# show trends ("auth.signin has been green for 6 runs and just regressed")
# instead of treating each run as a fresh universe.

: "${WARDEN_PASS:=0}"
: "${WARDEN_FAIL:=0}"
: "${WARDEN_SKIP:=0}"

_warden_audit_init() {
  : "${WARDEN_DIR:?WARDEN_DIR not set; lib/audit.sh sourced outside a plan}"
  : "${WARDEN_RUN_ID:?WARDEN_RUN_ID not set; lib/audit.sh sourced outside a plan}"
  : "${WARDEN_PLAN_NAME:=unknown}"
  mkdir -p "$WARDEN_DIR/runs"
}

_warden_iso_ts() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# warden_assert <pass|fail|skip> <id> [detail]
# Emits two channels:
#   - stdout: human line + WARDEN_RESULT line (the runner counts these)
#   - JSONL: append to runs/asserts.jsonl with full provenance
warden_assert() {
  _warden_audit_init
  local status="$1" id="$2" detail="${3:-}"

  case "$status" in
    pass) WARDEN_PASS=$((WARDEN_PASS + 1)); echo "  ok  $id${detail:+: $detail}" ;;
    fail) WARDEN_FAIL=$((WARDEN_FAIL + 1)); echo "  FAIL $id${detail:+: $detail}" ;;
    skip) WARDEN_SKIP=$((WARDEN_SKIP + 1)); echo "  skip $id${detail:+: $detail}" ;;
    *) echo "warden_assert: bad status '$status'" >&2; return 1 ;;
  esac

  if [[ -n "$detail" ]]; then
    echo "WARDEN_RESULT $status $id $detail"
  else
    echo "WARDEN_RESULT $status $id"
  fi

  if command -v jq >/dev/null 2>&1; then
    jq -cn \
      --arg run "$WARDEN_RUN_ID" \
      --arg plan "$WARDEN_PLAN_NAME" \
      --arg name "$id" \
      --arg status "$status" \
      --arg detail "$detail" \
      --arg at "$(_warden_iso_ts)" \
      '{run:$run, plan:$plan, name:$name, status:$status, detail:$detail, at:$at}' \
      >> "$WARDEN_DIR/runs/asserts.jsonl"
  fi
}

# warden_observe <name> <value> [note]
# Non-pass/fail data point. Use for measurements: timings, counts,
# version numbers, anything you want trended without it gating the run.
warden_observe() {
  _warden_audit_init
  local name="$1" value="$2" note="${3:-}"

  echo "  obs  $name=$value${note:+ ($note)}"

  if command -v jq >/dev/null 2>&1; then
    jq -cn \
      --arg run "$WARDEN_RUN_ID" \
      --arg plan "$WARDEN_PLAN_NAME" \
      --arg name "$name" \
      --arg value "$value" \
      --arg note "$note" \
      --arg at "$(_warden_iso_ts)" \
      '{run:$run, plan:$plan, name:$name, value:$value, note:$note, at:$at}' \
      >> "$WARDEN_DIR/runs/observations.jsonl"
  fi
}

# warden_save_state <key> <value>
# Persists across plans within a run (and across runs). Plan A writes
# WIKI_ID; plan B reads it via warden_get_state. Last write wins.
warden_save_state() {
  _warden_audit_init
  local key="$1" value="$2"
  local state="$WARDEN_DIR/runs/state"
  touch "$state"
  if grep -q "^${key}=" "$state"; then
    awk -v k="$key" -v v="$value" 'BEGIN{FS=OFS="="} $1==k{$0=k"="v} {print}' \
      "$state" > "$state.tmp" && mv "$state.tmp" "$state"
  else
    echo "${key}=${value}" >> "$state"
  fi
}

# warden_get_state <key> [default]
# Reads a key written by warden_save_state. Empty string if missing.
warden_get_state() {
  _warden_audit_init
  local key="$1" default="${2:-}"
  local state="$WARDEN_DIR/runs/state"
  if [[ ! -f "$state" ]]; then
    echo "$default"
    return
  fi
  local value
  value=$(grep "^${key}=" "$state" | tail -1 | cut -d= -f2-)
  echo "${value:-$default}"
}

# warden_halt <reason>
# Fatal failure: print reason, dump tail of any captured server log if
# present, exit non-zero. Use when the prerequisite for subsequent
# assertions has broken so badly that running them would mislead.
#
# Looks for the server log in (in order): $WARDEN_SERVER_LOG (set in
# warden.config.sh), /tmp/server.log, .warden/runs/server.log. Skips
# silently if none exist.
warden_halt() {
  _warden_audit_init
  local reason="$1"
  echo "  HALT $reason"
  echo "WARDEN_RESULT fail _halt $reason"
  local candidates=("${WARDEN_SERVER_LOG:-}" /tmp/server.log "$WARDEN_DIR/runs/server.log")
  for candidate in "${candidates[@]}"; do
    if [[ -n "$candidate" && -f "$candidate" ]]; then
      echo "--- last 50 lines of $candidate ---"
      tail -50 "$candidate"
      break
    fi
  done
  exit 1
}

# warden_summary (optional, for plans that want to print their own)
warden_summary() {
  echo ""
  echo "$WARDEN_PASS passed, $WARDEN_FAIL failed, $WARDEN_SKIP skipped"
}
