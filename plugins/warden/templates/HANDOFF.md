# Warden Handoff

> Session date: YYYY-MM-DD
> Context: one sentence on what state warden is in right now (e.g.
> "Full suite green except 3 frontend assertions; remediation tracked.")

A returning operator or a fresh agent reads this first. `/warden:resume`
parses this file and briefs the next session from it. Keep it current.

## Current state

### Stack

- **Service A** (`<path/to/src>`): one-line description, runs on port `<N>`
- **Service B**: same shape
- Backing infra: `postgres+<extensions>`, `redis`, message broker, queues
- Tenancy: single-tenant (one seeded user) or multi-tenant (seeded fixtures)

### What's running

How a contributor starts the stack from cold. Be literal.

```bash
cd <repo-root>
# warm shared packages first if needed
cd packages/shared && pnpm build && cd ../..
# launch services in the background
cd core && nohup pnpm dev > /tmp/<project>-core.log 2>&1 &
cd ../wiki && PORT=8080 nohup pnpm dev > /tmp/<project>-wiki.log 2>&1 &
```

### Auth & test credentials

- Strategy: `<cookie-session | jwt-bearer | jwt-cookie | api-key | basic-auth | custom>` (set in `warden.config.sh: WARDEN_AUTH_STRATEGY`)
- Sign-in endpoint: `<URL>` (`WARDEN_AUTH_SIGNIN_URL`)
- Default user: `$INITIAL_USERNAME` / `$INITIAL_PASSWORD` from `.env`
- Identity slots (if used): `WARDEN_USERS_admin_*`, `WARDEN_USERS_regular_*`

## Last run

Run with `bash .warden/run.sh` from project root.

- Run ID: `<YYYYMMDDTHHMMSS>` (see `.warden/runs/<id>.md`)
- Backend phase: `<N>/<M>` passing
- Frontend phase: `<N>/<M>` passing
- Ingest / pipeline phase: `<N>/<M>` passing

## Open remediation

Each failure has a self-contained file in `.warden/remediation/`,
written by `/warden:triage`. Priority order:

### Blockers (fix first, may unblock cascading failures)

- `<NN>-<slug>.md`: one-line summary. Cascades to N other failures.

### Auth and authorization

- `<NN>-<slug>.md`: one-line summary

### Pages not wired to API

- `<NN>-<slug>.md`: one-line summary

### UI bugs

- `<NN>-<slug>.md`: one-line summary

### API shape mismatch

- `<NN>-<slug>.md`: one-line summary

### Cascading (resolve automatically when blockers clear)

- `<NN>-<slug>.md`: one-line summary

## Patterns and hooks worth knowing

Where the project's load-bearing patterns live, so the next session
does not rediscover them.

- API client: `<path>` (auto-generated from OpenAPI, hand-written wrapper, etc.)
- Auth: `<path>` (better-auth, next-auth, custom; where the session check happens)
- Session hooks / store: `<path>`
- Sanitizers, validators, escape helpers: `<path>`

## Project-specific notes for warden

Anything in `warden.config.sh` that's non-obvious, any fixtures the
suite depends on, any tooling required beyond bash + curl + jq + psql.
