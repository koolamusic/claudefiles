#!/usr/bin/env bash
# .warden/lib/api.sh - HTTP API helpers that respect the auth strategy
#
# Thin wrappers over warden_authed_curl (from auth.sh) for the common
# JSON-API request shapes. Saves the boilerplate of curl flags and lets
# plans focus on the assertion.

# shellcheck disable=SC1091
source "${WARDEN_LIB:?WARDEN_LIB not set}/auth.sh"

# warden_api_get <url>
# Echoes response body.
warden_api_get() {
  local url="$1"
  warden_authed_curl "$url"
}

# warden_api_post <url> <json-body>
# Echoes response body.
warden_api_post() {
  local url="$1" body="$2"
  warden_authed_curl -X POST -H "Content-Type: application/json" -d "$body" "$url"
}

# warden_api_status <method> <url> [json-body]
# Echoes the HTTP status code. Does not emit body.
warden_api_status() {
  local method="$1" url="$2" body="${3:-}"
  if [[ -n "$body" ]]; then
    warden_authed_curl -o /dev/null -w "%{http_code}" \
      -X "$method" -H "Content-Type: application/json" -d "$body" "$url"
  else
    warden_authed_curl -o /dev/null -w "%{http_code}" -X "$method" "$url"
  fi
}

# warden_api_status_eq <id> <expected> <method> <url> [body]
# Asserts: GET/POST/etc returned exactly the expected status.
warden_api_status_eq() {
  local id="$1" expected="$2" method="$3" url="$4" body="${5:-}"
  local actual
  actual=$(warden_api_status "$method" "$url" "$body")
  if [[ "$actual" == "$expected" ]]; then
    warden_pass "$id" "$method $url returned $actual"
  else
    warden_fail "$id" "$method $url returned $actual, expected $expected"
  fi
}

# warden_api_json_path <url> <jq-path>
# GET, parse JSON, return value at jq path. Empty if missing.
warden_api_json_path() {
  local url="$1" path="$2"
  warden_api_get "$url" | jq -r "$path // empty" 2>/dev/null
}
