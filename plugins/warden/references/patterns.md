# Patterns

Recipes that show up across plans. Lift these verbatim.

## Login and reuse

One login at the top of a frontend plan, every subsequent assertion
inherits the session. Saves 5+ seconds per assertion.

```bash
source "$WARDEN_LIB/browser.sh"
warden_browser_login "$WIKI_URL/login" "$INITIAL_USERNAME" "$INITIAL_PASSWORD"
warden_pass login

warden_browser_open "$WIKI_URL/dashboard" ".dashboard-root" 8000
warden_browser_open "$WIKI_URL/settings" ".settings-page" 8000
# ... session persists for the whole plan
```

## Wait-until-ready

Plans should not assume the stack is ready when they start. Backing
services (Postgres, Redis) often take a second or two to accept
connections after the dev server starts.

```bash
source "$WARDEN_LIB/wait.sh"
warden_wait_pg 127.0.0.1 5432 postgres 30 || { warden_fail pg-ready; exit 0; }
warden_wait_redis 127.0.0.1 6379 30      || { warden_fail redis-ready; exit 0; }
warden_wait_http "$SERVER_URL/health" 30 || { warden_fail http-ready; exit 0; }
```

`exit 0` after a fatal prerequisite is intentional: keep the plan from
running pointless assertions, but do not crash the runner. The `warden_fail`
call already recorded the failure.

## Clean slate between runs

For destructive UAT suites that need a known-empty starting state, run
a reset before the suite. Most teams do this manually rather than
per-run, but if you need it:

```bash
psql -h 127.0.0.1 -U postgres -d <db> -f .warden/lib/wipe.sql
```

Keep the SQL in `lib/wipe.sql` so it can be version-controlled and
reviewed separately from plans.

## API-driven seeding

When you need rich content before running assertions, seed via the API
rather than direct DB inserts. Faster than agent-browser, more realistic
than fixtures bypassing application logic.

```bash
warden_signin "$INITIAL_USERNAME" "$INITIAL_PASSWORD"
warden_api_post "$SERVER_URL/widgets" '{"name":"smoke-widget","kind":"alpha"}' >/dev/null
```

For async pipelines, poll the database (or a status endpoint) until the
record materializes:

```bash
for _ in $(seq 1 30); do
  count=$(warden_psql_count widgets "name='smoke-widget'")
  [[ "$count" -eq 1 ]] && break
  sleep 1
done
[[ "$count" -eq 1 ]] && warden_pass widget-seeded || warden_fail widget-seeded "not visible after 30s"
```

## Multi-block scripts sharing variables

Plans can have multiple ```bash fences. The runner concatenates them
before execution, so variables flow across blocks.

```markdown
### Step 1
\`\`\`bash
USER_ID=$(curl -sf "$SERVER_URL/users/me" | jq -r '.id')
\`\`\`

### Step 2
\`\`\`bash
# USER_ID is visible here
curl -sf "$SERVER_URL/users/$USER_ID/wikis" > /tmp/wikis.json
\`\`\`
```

Useful for narrative plans where each section corresponds to a logical
step the reader should follow.

## Layered env loading

A monorepo with `backend/` and `frontend/` services often has env files
per service plus a shared root `.env`. List them in the order shell
should source them (later files overwrite earlier values per variable;
this is plain shell `source` semantics).

```bash
# In warden.config.sh:
ENV_FILES=(backend/.env .env)
```

```bash
# In a plan:
source "$WARDEN_LIB/env.sh"
warden_load_env
# All vars from backend/.env and .env are now exported
```

## Observations versus assertions

Not everything that matters is pass/fail. Boot times, queue depths,
response sizes, version strings: useful trend data that should not gate
the suite. Use `warden_observe`.

```bash
START=$(date +%s%N)
curl -sf "$SERVER_URL/health" >/dev/null
END=$(date +%s%N)
ELAPSED_MS=$(( (END - START) / 1000000 ))

warden_observe boot.health "${ELAPSED_MS}ms" "cold start"
# Then assert separately
[[ $ELAPSED_MS -lt 500 ]] && warden_pass boot.health.fast || warden_fail boot.health.fast "took ${ELAPSED_MS}ms"
```

Observations land in `.warden/runs/observations.jsonl`, append-only.
`/warden:report` reads them to show trends.

## Cross-plan state via warden_save_state

Plan A creates a resource and saves its ID. Plan B reads it.

```bash
# In plans/01-seed/01-create-wiki.md:
WIKI_ID=$(warden_api_post "$SERVER_URL/wikis" '{"type":"log","name":"x"}' | jq -r '.id')
warden_save_state WIKI_ID "$WIKI_ID"
warden_pass create-wiki

# In plans/01-seed/02-add-fragments.md (later in the run):
WIKI_ID=$(warden_get_state WIKI_ID)
[[ -n "$WIKI_ID" ]] || warden_halt "WIKI_ID missing; plan 01-create-wiki must run first"
warden_api_post "$SERVER_URL/wikis/$WIKI_ID/fragments" '...'
```

State persists in `.warden/runs/state` across runs. To reset between
full-suite runs, delete the file.

## Halt on fatal prerequisite

When a prerequisite for subsequent assertions has broken so badly that
running them would mislead, `warden_halt`. The runner records the
failure, dumps the tail of any captured server log it can find, and
exits non-zero.

```bash
warden_wait_pg 127.0.0.1 5432 postgres 10 || warden_halt "postgres unreachable, aborting suite"
```

Distinct from a single failed assertion. Use sparingly: only when the
whole run loses meaning, not when one feature is broken.

## Trap-based cleanup

Plans that mint temp files or hold resources should clean up.

```bash
COOKIE_JAR=$(mktemp /tmp/warden-cookies-XXXXXX.txt)
trap 'rm -f "$COOKIE_JAR"' EXIT
```

For most plans, `warden_signin` (cookie-session strategy) handles its
own cookie jar lifecycle. Use this pattern for project-specific temp
state outside the auth library.

## Idempotent naming

Plans that create real records in the DB will collide on re-run unless
names are unique. Suffix with a timestamp or run id.

```bash
TS=$(date +%s)
NAME="warden-test-wiki-$TS"
# or, to scope to the current run:
NAME="warden-test-wiki-$WARDEN_RUN_ID"
```

Pair with cleanup or a destructive reset between runs.
