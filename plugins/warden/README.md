# warden

A portable acceptance-test playbook for Claude Code. Project-coupled, sprint-agnostic. Three runtimes (bash, hurl, agent-browser), five commands, one project directory (`.warden/`) that travels with the repo and works without the plugin installed.

> Supported scope: Node.js and Go backends, Postgres for database assertions, cookie-session (better-auth shape) or JWT bearer auth. Frontend testing via agent-browser. Designed for macOS and Linux development machines.

## Commands

| Command | Purpose |
|---|---|
| `/warden:design <spec>` | Generate a plan. Self-bootstraps `.warden/` from plugin templates on first invocation, including auth strategy detection and config seeding. |
| `/warden:run [plan-id...]` | Execute `bash .warden/run.sh`. Honours phase ordering from `WARDEN_PHASES`. Forwards `--strict`, `--destructive`. |
| `/warden:triage [run-id]` | Classify failures from a run, write per-failure remediation files. Detects regressions vs new failures via the JSONL audit trail. |
| `/warden:report [run-id]` | WhatsApp-casual stakeholder summary. Lead with shipped vs regressed. |
| `/warden:resume` | Brief a fresh session from `.warden/HANDOFF.md`. |
| `/warden:doctor` | Health check for `.warden/`: engine drift, lib gaps, missing runtimes, audit-trail integrity, gitignore, plan format. |

## `.warden/` directory

```
.warden/
├── run.sh                 # the engine (project-owned; copied by /warden:design)
├── lib/                   # helper libraries (assert, audit, auth, api, db, browser, hurl, env, wait, parse)
├── warden.config.sh       # project knobs (phases, auth strategy, services, dotenv layering, destructive flag)
├── SEQUENCE.md            # human prose for the phase order
├── HANDOFF.md             # session resume state
├── plans/                 # markdown plans, bash extracted per fenced block
│   └── <phase>/<NN>-<slug>.md
├── fixtures/              # *.hurl files, JSON bodies, SQL seeds
├── logs/                  # gitignored, per-plan timestamped output
├── runs/                  # checked in: per-run .md summary + asserts.jsonl + observations.jsonl + state
└── remediation/           # per-failure tracked followups (one file each)
```

`.warden/` is the contract. `bash .warden/run.sh` works on any clone with no plugin installed.

## Runtimes

| Runtime | When | Library |
|---|---|---|
| **bash** | Process lifecycle, DB state, env presence, mixed scenarios | `lib/assert.sh`, `lib/env.sh`, `lib/wait.sh`, `lib/api.sh`, `lib/db.sh` |
| **hurl** | HTTP contracts (request/response shape, headers, chained flows) | `lib/hurl.sh`, fixtures under `.warden/fixtures/*.hurl` |
| **agent-browser** | UI rendering, form interaction, navigation outcomes | `lib/browser.sh` |

See `references/runtimes.md` for the choosing guide and `references/patterns.md` for recipes (login-and-reuse, wait-until-ready, MCP seeding, cross-plan state).

## The assertion contract

Plans `source "$WARDEN_LIB/assert.sh"` and call `warden_pass <id> [detail]`, `warden_fail <id> [detail]`, `warden_skip <id> [detail]`. Each emits:

1. A human-readable line for log readers
2. A `WARDEN_RESULT <kind> <id> [detail]` line that the runner counts by `grep`
3. A JSONL record appended to `.warden/runs/asserts.jsonl` with run id, plan name, timestamp

The runner counts `WARDEN_RESULT` lines only. Plan output containing the phrase "passed" or "failed" elsewhere is ignored. The JSONL trail survives across runs so `/warden:report` and `/warden:triage` can do trend and regression analysis.

## Auth

The auth library is a strategy router. Plans call a stable interface; the strategy is selected once in `warden.config.sh`.

```bash
# Plans always do this:
warden_signin "$EMAIL" "$PASSWORD"
warden_authed_curl "$SERVER_URL/users/me"

# The mechanism is configured once:
WARDEN_AUTH_STRATEGY=cookie-session    # or jwt-bearer, jwt-cookie, api-key, basic-auth, custom
WARDEN_AUTH_SIGNIN_URL="$SERVER_URL/api/auth/sign-in/email"
```

`/warden:design` discovers the project's auth approach on first run (inspects `package.json`, env files, route code) and writes the right strategy plus endpoint vars.

Multi-identity for authorization testing:

```bash
# In warden.config.sh:
WARDEN_USERS_admin_email="admin@example.com"
WARDEN_USERS_admin_password="adminpass"
WARDEN_USERS_regular_email="user@example.com"
WARDEN_USERS_regular_password="userpass"

# In a plan:
warden_signin_as admin
status=$(warden_api_status GET "$SERVER_URL/admin/users")
[[ "$status" == "200" ]] && warden_pass admin-allowed || warden_fail admin-allowed

warden_signin_as regular
status=$(warden_api_status GET "$SERVER_URL/admin/users")
[[ "$status" == "403" ]] && warden_pass admin-blocked || warden_fail admin-blocked
```

## Phases

`WARDEN_PHASES=(boot api pipeline frontend)` in `warden.config.sh` defines execution order. Plans under `.warden/plans/<phase>/*.md` run in numeric order within each phase. Plans at the root of `.warden/plans/` run first.

`SEQUENCE.md` is the human prose explaining why that order and what each phase seeds for the next. Read by contributors; not parsed by the runner.

## Cross-plan state

Plans share data via `warden_save_state KEY value` and `warden_get_state KEY`. State lives in `.warden/runs/state`, persists across runs (overwrite by writing a new value, reset by deleting the file).

```bash
# plan 01-seed/01-create.md
WIKI_ID=$(warden_api_post "$SERVER_URL/wikis" '{...}' | jq -r '.id')
warden_save_state WIKI_ID "$WIKI_ID"

# plan 02-verify/01-check.md (later in the same run, or in a future run)
WIKI_ID=$(warden_get_state WIKI_ID)
[[ -n "$WIKI_ID" ]] || warden_halt "WIKI_ID missing; seed plan must run first"
```

## Destructive suites

If `DESTRUCTIVE=1` in `warden.config.sh`, the runner shows a 5-second countdown before executing and refuses non-interactive invocation unless `--destructive` (or `--yes`, `--force`) is passed.

## Composes with jira

The jira plugin's `/jira:uat design` writes plans into `.warden/plans/` directly. Use `/jira:uat` when you have an active sprint and want sprint-coupled UAT lifecycle. Use `/warden:*` for project-wide coverage that outlives sprints, or in repos without jira.

## What lives in the plugin vs the project

- **Plugin (`~/.claude/plugins/warden/`)**: generator only (commands, templates, references). Updated via the marketplace.
- **Project (`<repo>/.warden/`)**: the engine, the libs, the plans, the audit trail. Owned by the repo; survives plugin uninstall; works without the plugin installed.

To compare an existing `.warden/` against the current plugin templates, run `/warden:doctor`. It reports any drift in `run.sh` and `lib/*.sh` as advisory; ask Claude to walk through the diff and pick what to sync. Project-owned engine drift is expected and supported, so there is no automatic upgrade path.

## References

- `references/runtimes.md`: when to reach for bash vs hurl vs agent-browser
- `references/patterns.md`: login-and-reuse, wait-until-ready, MCP seeding, cross-plan state, idempotent naming
- `references/antipatterns.md`: mocks, hardcoded URLs, missing assertions, early exits, decorative summaries

## Studio integration

Studio symlinks `.warden/` into `~/.studio/<project>/warden/` like it does for `.jira/` and `.project/`. No additional configuration; the warden plugin does not know or care.
