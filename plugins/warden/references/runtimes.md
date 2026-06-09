# Runtimes

Warden plans run in one of three runtimes. Pick the one that matches the
assertion surface, not the system under test.

## bash

Use for:
- Process lifecycle checks (server boots, env vars set, ports open)
- Database state assertions (rows present, columns populated, enums match)
- Backing service health (Postgres `pg_isready`, Redis `PING`)
- Any assertion that boils down to "shell out and check exit code or output"
- Mixed scenarios where bash is the glue between other tools

Strengths: zero install, full control, every other runtime is reachable
from bash anyway.

Weaknesses: HTTP assertions get verbose (curl plus jq plus exit-code
parsing). Multi-step DOM assertions are nearly impossible.

Helpers: `warden_load_env`, `warden_wait_{port,http,pg,redis}`, plus
`pass`/`fail`/`skip` from `assert.sh`.

## hurl

Use for:
- HTTP API contracts (request/response shape, headers, status codes)
- Chained request flows (auth, then call protected endpoint)
- Response time assertions
- JSON path assertions on response bodies
- OpenAPI-shape conformance

Strengths: declarative. The .hurl fixture is the contract; the plan is
two lines of bash that runs it. Easy to diff when an API changes.

Weaknesses: no access to the database, no UI, no shell. Strictly
request/response. Failure messages are less rich than custom bash.

Helpers: `warden_hurl_test <file> <id> [--variable ...]` from `hurl.sh`.

## agent-browser

Use for:
- UI-rendered page checks (element present, text visible)
- Form interactions (fill, click, submit)
- Auth flows that need real cookie handling
- Navigation outcomes (clicking X opens Y)
- Anything that requires JavaScript execution

Strengths: actual browser behaviour. JavaScript runs. Routing works.
Same as a real user.

Weaknesses: slow. State-leaky between tests if not managed. Selectors
break on UI churn. Setup includes Chromium and the MCP.

Helpers: `warden_browser_{login,open,query_exists,text_exists,eval_true,wait}`
from `browser.sh`.

## Choosing

If the assertion is "GET /foo returns 200 with body shape X", reach for
hurl. If the assertion is "click button Y and confirm modal Z renders",
reach for agent-browser. Everything else is bash.

A single plan can mix all three. Sourcing multiple lib files in one bash
block is fine; the runner does not care.
