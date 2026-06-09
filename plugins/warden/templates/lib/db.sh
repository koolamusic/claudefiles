#!/usr/bin/env bash
# .warden/lib/db.sh - postgres query helpers
#
# Generic over $DATABASE_URL. Plans use these to assert DB state without
# repeating psql flags every time. The library is intentionally psql-only
# for now; other databases are straightforward extensions.

# warden_psql_one <sql>
# Echoes a single scalar value, whitespace trimmed. Empty on error or
# zero-row result.
warden_psql_one() {
  local sql="$1"
  : "${DATABASE_URL:?DATABASE_URL not set}"
  psql "$DATABASE_URL" -tAX -c "$sql" 2>/dev/null | tr -d '[:space:]'
}

# warden_psql_count <table> [where-clause]
# Echoes integer row count. Returns 0 on connection failure.
warden_psql_count() {
  local table="$1" where="${2:-}"
  local sql="SELECT count(*) FROM $table"
  [[ -n "$where" ]] && sql="$sql WHERE $where"
  local result
  result=$(warden_psql_one "$sql")
  echo "${result:-0}"
}

# warden_psql_exec <sql>
# Runs a statement, swallows output. Returns 0 on success, non-zero on
# error. Use for INSERT/UPDATE/DELETE in plan setup.
warden_psql_exec() {
  local sql="$1"
  : "${DATABASE_URL:?DATABASE_URL not set}"
  psql "$DATABASE_URL" -q -X -c "$sql" >/dev/null 2>&1
}

# warden_psql_row_exists <id> <table> <where-clause>
# Asserts: exactly one row matches.
warden_psql_row_exists() {
  local id="$1" table="$2" where="$3"
  local count
  count=$(warden_psql_count "$table" "$where")
  if [[ "$count" == "1" ]]; then
    warden_pass "$id" "$table row exists ($where)"
  else
    warden_fail "$id" "$table count=$count for ($where), expected 1"
  fi
}
