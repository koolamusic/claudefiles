#!/usr/bin/env bash
# .warden/lib/wait.sh - poll-until-ready helpers
#
# Each helper polls every 1s up to a timeout (default 30s) and returns 0 on
# success, 1 on timeout. Designed for plan prerequisites: "wait until the
# server is ready before asserting against it."

warden_wait_port() {
  local host="$1" port="$2" timeout="${3:-30}"
  local elapsed=0
  while ! (echo > "/dev/tcp/${host}/${port}") 2>/dev/null; do
    sleep 1
    elapsed=$((elapsed + 1))
    if [[ $elapsed -ge $timeout ]]; then
      return 1
    fi
  done
}

warden_wait_http() {
  local url="$1" timeout="${2:-30}" expect="${3:-200}"
  local elapsed=0
  while true; do
    local code
    code=$(curl -sf -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    if [[ "$code" == "$expect" ]]; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
    if [[ $elapsed -ge $timeout ]]; then
      return 1
    fi
  done
}

warden_wait_pg() {
  local host="${1:-127.0.0.1}" port="${2:-5432}" user="${3:-postgres}" timeout="${4:-30}"
  local elapsed=0
  while ! pg_isready -h "$host" -p "$port" -U "$user" -q 2>/dev/null; do
    sleep 1
    elapsed=$((elapsed + 1))
    if [[ $elapsed -ge $timeout ]]; then
      return 1
    fi
  done
}

warden_wait_redis() {
  local host="${1:-127.0.0.1}" port="${2:-6379}" timeout="${3:-30}"
  local elapsed=0
  while [[ "$(redis-cli -h "$host" -p "$port" PING 2>/dev/null)" != "PONG" ]]; do
    sleep 1
    elapsed=$((elapsed + 1))
    if [[ $elapsed -ge $timeout ]]; then
      return 1
    fi
  done
}
