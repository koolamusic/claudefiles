#!/usr/bin/env bash
# .warden/lib/auth.sh - authentication strategy dispatch
#
# Plans call a stable interface (warden_signin, warden_authed_curl,
# warden_signin_as, warden_signout, warden_token). The actual mechanics
# vary per project (cookie-session, JWT bearer, API key, basic auth)
# and are selected by WARDEN_AUTH_STRATEGY in warden.config.sh.
#
# /warden:design inspects the project on first run and writes the right
# strategy + endpoint vars into warden.config.sh. This file is the
# router; it never gets per-project rewrites.
#
# Strategies:
#   cookie-session   POST creds; capture Set-Cookie to jar; -b on subsequent
#   jwt-bearer       POST creds; jq the JWT from response; Authorization: Bearer
#   jwt-cookie       JWT stored HttpOnly; same flow as cookie-session
#   api-key          Static token in env; no signin call
#   basic-auth       curl --user "$user:$pass"
#   custom           Project provides $WARDEN_AUTH_CUSTOM script
#
# Config vars (set in warden.config.sh):
#   WARDEN_AUTH_STRATEGY      one of the above
#   WARDEN_AUTH_SIGNIN_URL    POST endpoint (cookie-session, jwt-bearer)
#   WARDEN_AUTH_ORIGIN        CORS Origin header (cookie flows)
#   WARDEN_AUTH_TOKEN_PATH    jq path to JWT in response (default .token)
#   WARDEN_AUTH_HEADER        header name for api-key (default X-API-Key)
#   WARDEN_AUTH_TOKEN_ENV     env var holding the api-key (default AUTH_API_KEY)
#   WARDEN_AUTH_COOKIE_NAME   cookie name for jwt-cookie
#   WARDEN_AUTH_CUSTOM        path to a custom strategy script
#
# Multi-identity slots (optional):
#   WARDEN_USERS_<slot>_email
#   WARDEN_USERS_<slot>_password
# Then plans call warden_signin_as <slot>.

: "${WARDEN_AUTH_STRATEGY:=cookie-session}"

# State held in this shell:
#   WARDEN_AUTH_COOKIE_JAR   cookie-session, jwt-cookie
#   WARDEN_AUTH_TOKEN        jwt-bearer, api-key

warden_signin() {
  local user="$1" pass="$2"
  case "$WARDEN_AUTH_STRATEGY" in
    cookie-session) _warden_signin_cookie "$user" "$pass" ;;
    jwt-bearer)     _warden_signin_jwt    "$user" "$pass" ;;
    jwt-cookie)     _warden_signin_cookie "$user" "$pass" ;;
    api-key)        _warden_signin_apikey ;;
    basic-auth)     _warden_signin_basic  "$user" "$pass" ;;
    custom)         _warden_signin_custom "$user" "$pass" ;;
    *) echo "warden_signin: unknown strategy '$WARDEN_AUTH_STRATEGY'" >&2; return 1 ;;
  esac
}

warden_signin_as() {
  local slot="$1"
  local user_var="WARDEN_USERS_${slot}_email"
  local pass_var="WARDEN_USERS_${slot}_password"
  local user="${!user_var:-}"
  local pass="${!pass_var:-}"
  if [[ -z "$user" || -z "$pass" ]]; then
    echo "warden_signin_as: slot '$slot' not configured ($user_var / $pass_var missing)" >&2
    return 1
  fi
  warden_signin "$user" "$pass"
}

warden_signout() {
  if [[ -n "${WARDEN_AUTH_COOKIE_JAR:-}" && -f "$WARDEN_AUTH_COOKIE_JAR" ]]; then
    rm -f "$WARDEN_AUTH_COOKIE_JAR"
  fi
  unset WARDEN_AUTH_COOKIE_JAR WARDEN_AUTH_TOKEN
}

warden_token() {
  echo "${WARDEN_AUTH_TOKEN:-}"
}

# warden_authed_curl <curl-args...>
# Runs curl with active credentials injected per strategy.
warden_authed_curl() {
  case "$WARDEN_AUTH_STRATEGY" in
    cookie-session|jwt-cookie)
      curl -s -b "${WARDEN_AUTH_COOKIE_JAR:-/dev/null}" "$@"
      ;;
    jwt-bearer)
      curl -s -H "Authorization: Bearer ${WARDEN_AUTH_TOKEN:-}" "$@"
      ;;
    api-key)
      curl -s -H "${WARDEN_AUTH_HEADER:-X-API-Key}: ${WARDEN_AUTH_TOKEN:-}" "$@"
      ;;
    basic-auth)
      curl -s --user "${WARDEN_AUTH_BASIC:-}" "$@"
      ;;
    custom)
      _warden_authed_curl_custom "$@"
      ;;
    *) echo "warden_authed_curl: unknown strategy '$WARDEN_AUTH_STRATEGY'" >&2; return 1 ;;
  esac
}

# Per-strategy implementations
# -----------------------------------------------------------------------

_warden_signin_cookie() {
  local user="$1" pass="$2"
  : "${WARDEN_AUTH_SIGNIN_URL:?WARDEN_AUTH_SIGNIN_URL not set in warden.config.sh}"
  WARDEN_AUTH_COOKIE_JAR="${WARDEN_AUTH_COOKIE_JAR:-$(mktemp /tmp/warden-cookies-XXXXXX.txt)}"
  local headers=(-H "Content-Type: application/json")
  if [[ -n "${WARDEN_AUTH_ORIGIN:-}" ]]; then
    headers+=(-H "Origin: $WARDEN_AUTH_ORIGIN")
  fi
  curl -s -c "$WARDEN_AUTH_COOKIE_JAR" -X POST \
    "${headers[@]}" \
    -d "{\"email\":\"$user\",\"password\":\"$pass\"}" \
    "$WARDEN_AUTH_SIGNIN_URL" \
    >/dev/null
}

_warden_signin_jwt() {
  local user="$1" pass="$2"
  : "${WARDEN_AUTH_SIGNIN_URL:?WARDEN_AUTH_SIGNIN_URL not set in warden.config.sh}"
  local response
  response=$(curl -s \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$user\",\"password\":\"$pass\"}" \
    "$WARDEN_AUTH_SIGNIN_URL")
  WARDEN_AUTH_TOKEN=$(echo "$response" | jq -r "${WARDEN_AUTH_TOKEN_PATH:-.token}")
  if [[ -z "$WARDEN_AUTH_TOKEN" || "$WARDEN_AUTH_TOKEN" == "null" ]]; then
    echo "warden_signin: empty token from $WARDEN_AUTH_SIGNIN_URL" >&2
    return 1
  fi
  export WARDEN_AUTH_TOKEN
}

_warden_signin_apikey() {
  local token_env="${WARDEN_AUTH_TOKEN_ENV:-AUTH_API_KEY}"
  WARDEN_AUTH_TOKEN="${!token_env:-}"
  if [[ -z "$WARDEN_AUTH_TOKEN" ]]; then
    echo "warden_signin: $token_env is empty" >&2
    return 1
  fi
  export WARDEN_AUTH_TOKEN
}

_warden_signin_basic() {
  WARDEN_AUTH_BASIC="$1:$2"
  export WARDEN_AUTH_BASIC
}

_warden_signin_custom() {
  : "${WARDEN_AUTH_CUSTOM:?WARDEN_AUTH_CUSTOM not set; expected path to a custom strategy script}"
  # shellcheck disable=SC1090
  source "$WARDEN_AUTH_CUSTOM"
  _warden_signin_custom_impl "$@"
}

_warden_authed_curl_custom() {
  : "${WARDEN_AUTH_CUSTOM:?WARDEN_AUTH_CUSTOM not set}"
  _warden_authed_curl_custom_impl "$@"
}
