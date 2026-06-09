#!/usr/bin/env bash
# .warden/warden.config.sh - project configuration for warden
#
# This file is sourced by .warden/run.sh on every invocation. It declares
# project-specific knobs: phase ordering, environment file layering,
# pre-flight checks, runtime checks, auth strategy, service URLs, and
# any flags that change runner behaviour.

# Phase ordering. Plans under .warden/plans/<phase>/*.md run in the
# order declared here, alphabetical within each phase. Plans at the root
# of .warden/plans/ always run first.
#
# Empty array = run every plan under .warden/plans/**/*.md alphabetically.
WARDEN_PHASES=()

# Dotenv layering for warden_load_env (lib/env.sh). First file's vars
# are loaded first; later files only fill in vars not already set.
# Paths are relative to PROJECT_ROOT.
ENV_FILES=(.env)

# Pre-flight runs before any plan. Each entry is a shell command;
# non-zero exit prints a warning (and aborts if --strict).
#
# Example:
#   PREFLIGHT=(
#     "pg_isready -h 127.0.0.1 -p 5432 -U postgres -q"
#     "redis-cli -h 127.0.0.1 -p 6379 PING | grep -q PONG"
#   )
PREFLIGHT=()

# RUNTIME_CHECKS warn (always non-fatal) if a tool is missing.
#   RUNTIME_CHECKS=("command -v hurl" "npx agent-browser --version")
RUNTIME_CHECKS=()

# DESTRUCTIVE=1 means this suite mutates state. The runner shows a
# countdown and refuses non-interactive invocation unless --destructive
# or --yes is passed. Default 0.
DESTRUCTIVE=0

# Auth strategy. /warden:design discovers the project's auth approach
# and sets this. lib/auth.sh dispatches off it.
#
#   cookie-session   POST creds, capture Set-Cookie, -b on subsequent
#   jwt-bearer       POST creds, extract JWT from body, Authorization header
#   jwt-cookie       JWT in HttpOnly cookie (same flow as cookie-session)
#   api-key          Static key in env, no signin call
#   basic-auth       curl --user
#   custom           Project overrides via WARDEN_AUTH_CUSTOM script
WARDEN_AUTH_STRATEGY=cookie-session

# Auth endpoint config. Exact var requirement depends on strategy.
#   cookie-session / jwt-bearer / jwt-cookie:
#     WARDEN_AUTH_SIGNIN_URL    POST endpoint
#     WARDEN_AUTH_ORIGIN        CORS Origin header (cookie flows)
#   jwt-bearer:
#     WARDEN_AUTH_TOKEN_PATH    jq path to JWT in response (default .token)
#   api-key:
#     WARDEN_AUTH_HEADER        header name (default X-API-Key)
#     WARDEN_AUTH_TOKEN_ENV     env var holding the key (default AUTH_API_KEY)
#   jwt-cookie:
#     WARDEN_AUTH_COOKIE_NAME   cookie name carrying the JWT
#   custom:
#     WARDEN_AUTH_CUSTOM        path to a script defining
#                               _warden_signin_custom_impl and
#                               _warden_authed_curl_custom_impl
# WARDEN_AUTH_SIGNIN_URL="$SERVER_URL/api/auth/sign-in/email"
# WARDEN_AUTH_ORIGIN="$SERVER_URL"

# Multi-identity slots (optional). Used by warden_signin_as <slot>.
#   WARDEN_USERS_admin_email="admin@example.com"
#   WARDEN_USERS_admin_password="adminpass"
#   WARDEN_USERS_regular_email="user@example.com"
#   WARDEN_USERS_regular_password="userpass"

# Service URLs. Export so plans inherit defaults.
#   export SERVER_URL="${SERVER_URL:-http://localhost:3000}"
#   export WIKI_URL="${WIKI_URL:-http://localhost:8080}"
