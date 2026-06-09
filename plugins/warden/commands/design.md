---
description: "Generate a warden plan from a spec, GitHub issue, or interactive description. Self-bootstraps `.warden/` from plugin templates on first invocation, including project-aware auth strategy detection and config seeding."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: "<spec | --issue N | --from-plan path>"
---

Design a warden acceptance plan for the current project. Two modes depending on whether `.warden/` already exists.

## Parse the input

`$ARGUMENTS`:
- A free-text spec describing what to verify ("the auth flow signs a user in and the dashboard renders"). Default mode.
- `--issue N` to pull the spec from GitHub issue N (uses `gh issue view N --json title,body`).
- `--from-plan <path>` to model the new plan on an existing one.

If empty, ask the user what feature or behaviour they want to verify.

## Detect state

```bash
WARDEN_DIR=".warden"
if [ -d "$WARDEN_DIR" ]; then
  MODE=plan
else
  MODE=first-run
fi
```

## Mode: first-run

`.warden/` does not exist. Detect the project's shape, confirm decisions with the user, copy templates from the plugin into the project, then write the first plan.

### 1. Detect tech stack and auth strategy

Inspect what's in the repo. Report findings to the user before asking anything.

**Read these files if present** (use Read, no need to run shell tools for known paths):
- `package.json` (check `dependencies` + `devDependencies` for auth libs)
- `pyproject.toml`, `requirements.txt`, `Pipfile`
- `Cargo.toml`, `go.mod`
- `.env`, `.env.example`, `core/.env`, `core/.env.example`, `backend/.env.example`
- `openapi.json`, `openapi.yaml` (look for `securitySchemes`)

**Grep targets** (Glob/Grep; keep scope tight, don't read whole files):
- Auth lib imports and middleware: `better-auth`, `next-auth`, `lucia`, `passport`, `jose`, `jsonwebtoken`, `@clerk/`, `@auth0/`, `Authorization: Bearer`, `Set-Cookie`, `cookies.set`, `res.cookie`, `@UseGuards`, `@requires_auth`, `[Authorize]`, `X-API-Key`, `process.env.API_KEY`
- Auth-shaped env vars: `BETTER_AUTH_SECRET`, `NEXTAUTH_SECRET`, `JWT_SECRET`, `JWT_PRIVATE_KEY`, `SESSION_SECRET`, `COOKIE_DOMAIN`, `AUTH_API_KEY`

**Map findings to a strategy hypothesis:**

| Signal | Strategy |
|---|---|
| `better-auth`, `next-auth`, `lucia`, `Set-Cookie`, `BETTER_AUTH_SECRET` | `cookie-session` |
| `jsonwebtoken`, `jose`, `Authorization: Bearer`, `JWT_SECRET`, `JWT_PRIVATE_KEY` | `jwt-bearer` |
| HttpOnly cookies containing a JWT, `JWT_COOKIE_NAME` | `jwt-cookie` |
| `X-API-Key`, `process.env.API_KEY` only (no signin endpoint) | `api-key` |
| `@clerk/`, `@auth0/`, `next-auth` providers (Google, GitHub) | `custom` |
| Nothing matches | ask the user |

### 2. Detect services, ports, env files

- Read `package.json` scripts for `PORT=` patterns
- Read `docker-compose.yml` / `compose.yaml` services + ports
- Note any workspace split (`core/` vs `wiki/`, `backend/` vs `frontend/`)
- Identify dotenv layering: `core/.env` plus `.env` is common in monorepos

### 3. Confirm decisions interactively

Use `AskUserQuestion` with one block of up to 4 questions, recommended option first. Skip any question where detection is unambiguous.

**Question 1 (always ask if hypothesis is unclear):** "Which auth strategy fits this project?"
- Options listed with the detection rationale on the recommended one (e.g. "cookie-session (detected: BETTER_AUTH_SECRET in core/.env.example and `Set-Cookie` in core/src/routes/auth.ts:42)")
- header: "Auth"

**Question 2 (if multiple service hosts detected):** "Which URLs should plans assume?"
- header: "Services"
- options: detected ports, or "I'll fill them in"

**Question 3 (if signin URL detected but uncertain):** "Sign-in endpoint?"
- header: "Signin URL"
- options: detected paths

**Question 4 (if multiple identity hints, admin/user fixtures, role columns):** "Set up multi-identity slots?"
- header: "Identities"
- options: "Yes, admin + regular" / "Yes, just admin" / "No, single user"

Take answers and form a config block.

### 4. Bootstrap `.warden/`

Copy the engine templates verbatim. Personalize the config and stub files.

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:?CLAUDE_PLUGIN_ROOT not set}"

mkdir -p .warden/lib .warden/plans .warden/fixtures .warden/logs .warden/runs .warden/remediation

cp "$PLUGIN_ROOT/templates/run.sh"          .warden/run.sh
cp "$PLUGIN_ROOT/templates/lib/"*.sh        .warden/lib/
cp "$PLUGIN_ROOT/templates/SEQUENCE.md"     .warden/SEQUENCE.md
cp "$PLUGIN_ROOT/templates/HANDOFF.md"      .warden/HANDOFF.md
```

Then write `.warden/warden.config.sh` populating the discovered values. Start from `$PLUGIN_ROOT/templates/warden.config.sh` and edit the relevant lines:

- `WARDEN_AUTH_STRATEGY=` <chosen strategy>
- `WARDEN_AUTH_SIGNIN_URL=` (only if strategy is cookie-session / jwt-bearer / jwt-cookie)
- `WARDEN_AUTH_ORIGIN=` (only cookie flows)
- `ENV_FILES=(...)` reflecting discovered layering
- Service URL exports (`SERVER_URL`, `WIKI_URL`, etc) under the appropriate comment block

For multi-identity, append `WARDEN_USERS_admin_email=...` lines from the user's input. Do not hardcode passwords; leave placeholders and tell the user to fill them in.

Update `.gitignore` to exclude `.warden/logs/`:

```bash
if [ -f .gitignore ] && ! grep -q '^\.warden/logs/' .gitignore; then
  echo ".warden/logs/" >> .gitignore
fi
```

### 5. Personalize HANDOFF.md

Replace the template's placeholder lines with what you detected: actual stack paths, ports, auth strategy, dotenv layering, "What's running" startup commands if you can infer them from package.json scripts.

Keep it as a starting point; tell the user what was filled in and what still needs editing.

### 6. Write the first plan

Continue to "Mode: plan" using the spec the user originally provided.

---

## Mode: plan

`.warden/` exists. Write a new plan based on `$ARGUMENTS`.

### 1. Pick the runtime

From the spec, decide:

| Spec shape | Runtime |
|---|---|
| GET/POST endpoints, JSON shape, response status | `hurl` if response/header assertions are heavy, else `bash` + curl |
| Page rendering, DOM interaction, navigation, forms | `agent-browser` |
| Database state, env presence, file checks, process lifecycle | `bash` |
| Mixed (login + UI + DB check) | `bash` (it can call all the helpers) |

When uncertain, use bash. The lib helpers compose.

### 2. Pick the phase and the next NN

Read `.warden/warden.config.sh` for `WARDEN_PHASES`. If a phase suits the spec (auth → matches an `auth` phase; UI → matches a `frontend` phase), place the new plan there. Otherwise place it at the root of `.warden/plans/`.

Find the next sequence number by reading the existing files in the target directory:

```bash
PHASE_DIR=".warden/plans${PHASE:+/$PHASE}"
NEXT_NN=$(printf "%02d" $(( $(ls "$PHASE_DIR" 2>/dev/null | grep -oE '^[0-9]+' | sort -n | tail -1 || echo 0) + 1 )))
```

Slug the spec into kebab-case for the filename (e.g. "auth flow works" → `auth-flow-works`).

### 3. Read the matching template as a style reference

For the chosen runtime, `Read` one of:
- `$PLUGIN_ROOT/templates/plan-bash.md`
- `$PLUGIN_ROOT/templates/plan-hurl.md`
- `$PLUGIN_ROOT/templates/plan-browser.md`

Use the structure (headings, prerequisites section, multi-block bash with named steps) and the lib helpers it demonstrates. Do not copy verbatim; produce a fresh plan for the actual spec.

### 4. Write the plan

`Write` to `$PHASE_DIR/<NN>-<slug>.md`.

Required sections:
- `# <NN> - <Title>` heading
- `## What it proves`
- `## Prerequisites`
- One or more `### Step` headings with bash blocks
- First bash block starts with `set -uo pipefail` and `source "$WARDEN_LIB/assert.sh"`
- Every check produces a `warden_pass` or `warden_fail` call (see references/antipatterns.md for the silent-green failure mode)

### 5. Report back

Tell the user:
- Path written
- Runtime chosen and why
- One-liner to run it: `bash .warden/run.sh <NN>-<slug>`
- Any prerequisites the user needs to satisfy first (services running, env vars, fixtures)

## Error paths

- `.warden/` exists but is corrupted (missing `run.sh` or `lib/`): tell the user, suggest deleting `.warden/` and re-running for first-run mode. Do not silently overwrite.
- Detection turns up nothing usable for auth: fall back to asking the user directly, no hypothesis offered.
- `$ARGUMENTS` empty: ask the user for the spec via AskUserQuestion before doing any work.
