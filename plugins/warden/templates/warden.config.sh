#!/usr/bin/env bash
# .warden/warden.config.sh - project configuration for warden
#
# This file is sourced by .warden/run.sh on every invocation. It declares
# project-specific knobs: phase ordering, environment file layering,
# pre-flight checks, runtime availability checks, and any service URLs
# plans need.

# WARDEN_PHASES sets the execution order for phase subdirectories under
# .warden/plans/. Plans living at .warden/plans/<phase>/*.md are run in
# the order declared here, alphabetically within each phase. Plans at the
# root .warden/plans/ run first.
#
# Empty array means: run every plan under .warden/plans/**/*.md in
# alphabetical order, no phase grouping.
WARDEN_PHASES=()

# ENV_FILES lists dotenv files sourced by `warden_load_env` (from
# lib/env.sh). First file's vars are loaded first; later files only add
# vars that were not already set.
#
# Paths are relative to PROJECT_ROOT.
ENV_FILES=(.env)

# PREFLIGHT runs before any plan starts. Each entry is a shell command;
# non-zero exit prints a warning (and aborts the suite if --strict is set).
#
# Example:
#   PREFLIGHT=(
#     "pg_isready -h 127.0.0.1 -p 5432 -U postgres -q"
#     "redis-cli -h 127.0.0.1 -p 6379 PING | grep -q PONG"
#   )
PREFLIGHT=()

# RUNTIME_CHECKS warn (always non-fatal) if a runtime tool is missing.
# Use this for tools that some plans depend on but not all.
#
# Example:
#   RUNTIME_CHECKS=(
#     "command -v hurl"
#     "npx agent-browser --version"
#   )
RUNTIME_CHECKS=()

# Service URLs. Export them so plans inherit defaults.
# Example:
#   export CORE_URL="${CORE_URL:-http://localhost:3000}"
#   export WIKI_URL="${WIKI_URL:-http://localhost:8080}"
