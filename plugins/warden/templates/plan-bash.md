# 01 - Server boot

> Reference plan for the **bash** runtime. Use as a style guide for any
> plan that drives the system under test with raw shell commands.

## What it proves

The server starts cleanly, serves `/health` with status 200, and the
backing services (Postgres, Redis) are reachable.

## Prerequisites

- Postgres reachable on `$DATABASE_URL`
- Redis reachable on `$REDIS_URL`
- Server running on `$SERVER_URL` (default `http://localhost:3000`)

## Steps

Each fenced ```bash block is run in order. Variables declared in earlier
blocks are visible to later blocks (the runner concatenates blocks before
executing).

### Health check

```bash
source "$WARDEN_LIB/assert.sh"
source "$WARDEN_LIB/env.sh"
source "$WARDEN_LIB/wait.sh"

warden_load_env

SERVER_URL="${SERVER_URL:-http://localhost:3000}"

if warden_wait_http "$SERVER_URL/health" 30 200; then
  warden_pass health-endpoint "GET /health returned 200 within 30s"
else
  warden_fail health-endpoint "GET /health did not return 200 within 30s"
fi

status=$(curl -sf "$SERVER_URL/health" | jq -r '.status' 2>/dev/null || echo "")
if [[ "$status" == "ok" ]]; then
  warden_pass health-shape ".status == 'ok'"
else
  warden_fail health-shape ".status was '$status', expected 'ok'"
fi
```

### Backing services

```bash
if warden_wait_pg 127.0.0.1 5432 postgres 5; then
  warden_pass pg-reachable "postgres on 127.0.0.1:5432"
else
  warden_fail pg-reachable "postgres unreachable"
fi

if warden_wait_redis 127.0.0.1 6379 5; then
  warden_pass redis-reachable "redis on 127.0.0.1:6379"
else
  warden_fail redis-reachable "redis unreachable"
fi
```

### Required env vars

```bash
for var in DATABASE_URL REDIS_URL INITIAL_USERNAME INITIAL_PASSWORD; do
  val="${!var:-}"
  if [[ -n "$val" ]]; then
    warden_pass "env-$var" "is set"
  else
    warden_fail "env-$var" "is missing"
  fi
done
```
