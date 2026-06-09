#!/usr/bin/env bash
# .warden/lib/assert.sh - thin wrappers over audit.sh
#
# Plans `source "$WARDEN_LIB/assert.sh"` and get the full primitive set:
# pass/fail/skip plus the audit/state/halt helpers transitively. The
# WARDEN_RESULT line + JSONL emission both happen inside warden_assert.

# shellcheck disable=SC1091
source "${WARDEN_LIB:?WARDEN_LIB not set}/audit.sh"

warden_pass() { warden_assert pass "$@"; }
warden_fail() { warden_assert fail "$@"; }
warden_skip() { warden_assert skip "$@"; }
