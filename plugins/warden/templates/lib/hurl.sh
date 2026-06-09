#!/usr/bin/env bash
# .warden/lib/hurl.sh - hurl runner to WARDEN_RESULT bridge
#
# Wraps `hurl --test <file>` and translates the result into a single
# warden_pass / warden_fail call. Additional hurl args (variables, env
# vars, parallel, etc) flow through as positional args after the id.
#
# Requires hurl: https://hurl.dev

warden_hurl_test() {
  local file="$1"
  local id="${2:-$(basename "$file" .hurl)}"
  shift 2 2>/dev/null || shift 1
  local extra_args=("$@")

  local log
  log="$(mktemp)"
  if hurl --test "${extra_args[@]}" "$file" > "$log" 2>&1; then
    warden_pass "$id"
    rm -f "$log"
  else
    local detail
    detail="$(grep -m1 -E "(error|FAIL)" "$log" | head -1 || echo "hurl test failed")"
    warden_fail "$id" "$detail"
    if [[ -n "${WARDEN_LOG:-}" ]]; then
      echo "--- hurl output for $id ---" >> "$WARDEN_LOG"
      cat "$log" >> "$WARDEN_LOG"
    fi
    rm -f "$log"
  fi
}
