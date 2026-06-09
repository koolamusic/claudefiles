---
description: "Design a warden acceptance plan through guided spec gathering. Detects existing planning artifacts (GSD, jira sprint, GitHub issue) and reads them as the spec source, or walks the user through adaptive Q&A. Self-bootstraps `.warden/` on first invocation."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: "[<spec> | --issue N | --from-plan path | --source <auto|interactive|...>]"
---

Design a warden acceptance plan for the current project. The command's job is to converge on a clear, testable spec, then write a plan that verifies it. Spec gathering is the load-bearing step; do not skip past it.

**Supported scope.** Node.js and Go backends with cookie-session (better-auth shape) or JWT bearer auth; Postgres for database assertions; agent-browser for UI; macOS and Linux dev machines. Other stacks may work via the `custom` auth strategy and skipping unused libs, but are not first-class.

## Parse the input

`$ARGUMENTS`:
- A free-text spec describing what to verify. Used as a starting point for the converge loop.
- `--issue N`: pull the spec from GitHub issue N (`gh issue view N --json title,body`). Counts as a planning artifact.
- `--from-plan <path>`: model the new plan on an existing one. Counts as a planning artifact.
- `--source auto`: skip the source-picker and use whichever planning artifact ranks first (see "Detect planning artifacts" below).
- `--source interactive`: skip the source-picker and force interactive Q&A.

Empty `$ARGUMENTS` is fine. Spec gathering will proceed from interactive Q&A.

## Mode: detect

```bash
WARDEN_DIR=".warden"
if [ -d "$WARDEN_DIR" ]; then MODE=plan; else MODE=first-run; fi
```

## Stage 1: bootstrap (first-run only)

`.warden/` does not exist. Run the bootstrap once. The first plan is written in Stage 3 below.

### 1.1 Detect tech stack and auth strategy

Inspect (use Read for known paths, Glob/Grep tight scope; no whole-file reads):

- `package.json` deps (`better-auth`, `next-auth`, `lucia`, `passport`, `jose`, `jsonwebtoken`, `@clerk/`, `@auth0/`)
- `pyproject.toml`, `requirements.txt`, `Pipfile`
- `Cargo.toml`, `go.mod`
- `.env`, `.env.example`, `backend/.env`, `backend/.env.example`, `<service>/.env*` for any workspace package
- `openapi.json` / `openapi.yaml` `securitySchemes`

Grep targets:
- `Set-Cookie`, `cookies.set`, `res.cookie` → cookie-session
- `Authorization: Bearer`, `verify_jwt`, `jwt.sign` → jwt-bearer
- `X-API-Key`, `process.env.API_KEY` → api-key
- `@UseGuards`, `@requires_auth`, `[Authorize]` → role-based; multi-identity is likely needed
- Auth-shaped env vars: `BETTER_AUTH_SECRET`, `NEXTAUTH_SECRET`, `JWT_SECRET`, `JWT_PRIVATE_KEY`, `SESSION_SECRET`, `COOKIE_DOMAIN`, `AUTH_API_KEY`

Hypothesize strategy. If unambiguous, set silently; only confirm when uncertain.

**Env file discovery.** Glob for `.env*` files at project root and one level deep inside detected workspace packages. Record what's found. Common layouts: root-only (`.env`), monorepo (`backend/.env` plus root `.env`), per-service (`services/<name>/.env`). The default `ENV_FILES=(.env)` only fits root-only projects; never assume it without checking. Note `warden_load_env` uses plain shell `source` semantics (later files in the array overwrite earlier values per variable), so list them in the order the project expects them merged.

### 1.2 Confirm uncertain decisions

Use `AskUserQuestion` with up to 4 questions in one block. Skip any question whose answer is unambiguous from detection. Recommended option always first.

Candidates:
- Auth strategy (only if hypothesis is uncertain)
- Service URLs (only if multiple hosts detected and ports ambiguous)
- Signin URL (only if multiple paths plausible)
- Env files (whenever multiple `.env*` candidates exist; do not silently default to `(.env)`)
- Multi-identity slots (only if admin/user fixtures or role columns detected)

### 1.3 Copy templates into `.warden/`

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:?CLAUDE_PLUGIN_ROOT not set}"
mkdir -p .warden/lib .warden/plans .warden/fixtures .warden/logs .warden/runs .warden/remediation
cp "$PLUGIN_ROOT/templates/run.sh"          .warden/run.sh
cp "$PLUGIN_ROOT/templates/lib/"*.sh        .warden/lib/
cp "$PLUGIN_ROOT/templates/SEQUENCE.md"     .warden/SEQUENCE.md
cp "$PLUGIN_ROOT/templates/HANDOFF.md"      .warden/HANDOFF.md
```

Then write `.warden/warden.config.sh` populating discovered values: auth strategy, signin URL, origin, env file layering, service URL exports, optional user slots. Use `$PLUGIN_ROOT/templates/warden.config.sh` as the starting structure.

Update `.gitignore`:

```bash
if [ -f .gitignore ] && ! grep -q '^\.warden/logs/' .gitignore; then
  echo ".warden/logs/" >> .gitignore
fi
```

### 1.4 Personalize HANDOFF.md

Fill in: stack paths, ports, auth strategy, dotenv layering, "What's running" startup commands inferred from package.json scripts. Leave clear placeholders for what you couldn't infer.

## Stage 2: converge on a spec

This stage runs in both modes. The goal is a clear, testable spec. Do not write a plan until the spec is concrete enough that you could explain to a contributor exactly what passes and what fails.

### 2.1 Detect planning-artifact candidates

Sources, in priority order:

1. **`--from-plan <path>`** if passed: model on that plan.
2. **`--issue N`** if passed: that GitHub issue is the source.
3. **`$ARGUMENTS` free text** if non-empty: starting point for refinement.
4. **`.jira/sprints/<current>/`** if present: read `.jira/CURRENT`, then read `BRIEF.md`, `CONTEXT.md`, `VERIFICATION.md`, and any `*-PLAN.md` in the active sprint. These already encode acceptance criteria the jira workflow produced.
5. **`.planning/active/`** if present (GSD): read `SPEC.md`, `PLAN.md`, `RESEARCH.md` from the active phase. GSD discuss-phase output is high-signal.
6. **`.project/ROADMAP.md`** if present (studio): goals + phase breakdown.
7. **`.warden/plans/`** existing: surface as "extend an existing plan" candidates.

For each detected source, record path, title (first heading), and one-line summary.

### 2.2 Pick the source

If `--source auto` was passed, use the highest-priority detected source without prompting.

If `--source interactive` was passed, skip detection and jump to Q&A.

Otherwise use `AskUserQuestion` to present candidates plus "Interactive Q&A" as the fallback. Frame the recommended choice (highest priority) first. Example header: `Spec source`.

Example shape (single question, omit options that don't apply):

> "Which spec source should warden use?"
> - "GSD active phase: .planning/active/SPEC.md (Recommended)"
> - "Jira sprint: .jira/sprints/2026-06-09-publish-fix/CONTEXT.md"
> - "GitHub issue #408 (you passed --issue 408)"
> - "Free text you typed: '<first 60 chars>'"
> - "Interactive Q&A (I'll ask you 2-3 questions)"

### 2.3 Source: planning artifact

Read the chosen artifact. Extract:

- **Subject under test**: what feature, endpoint, page, or behavior.
- **Acceptance criteria**: explicit pass/fail conditions. Look for Given/When/Then, "must", "should", or numbered acceptance lists.
- **Prerequisites**: what state must exist (services running, data seeded, identity active).
- **Identity scope**: anonymous, single authenticated user, multi-role.
- **Cross-cutting concerns**: auth, persistence, queueing, third-party integrations.

If any of these are missing or ambiguous after reading, ask 1-2 follow-up questions via `AskUserQuestion` to fill the gap. Do not write a plan with unresolved ambiguity.

### 2.4 Source: free text from `$ARGUMENTS`

Use the text as the subject. Ask up to 3 questions to flesh out the rest:

- "What does success look like? (the assertion shape)" with options pulled from runtime fit: HTTP API contract / page renders / database state / mixed.
- "Identity requirements?" Anonymous / single seeded user / multi-role / not applicable.
- "Prerequisites the test must seed itself, or expect existing?"

Skip any question whose answer is already clear from the text.

### 2.5 Source: interactive Q&A (no artifact, no input)

Run two rounds at most. Each round uses `AskUserQuestion` with up to 4 questions.

**Round 1 (subject + shape):**

1. "What's the feature or behavior you want warden to verify?" (header: `Subject`, free-text via Other)
2. "What's the assertion shape?" (header: `Shape`). Options: HTTP API contract, page renders, database state, background job completes, multi-step flow.
3. "Identity scope?" (header: `Identity`). Options: anonymous, single user, multi-role, not applicable.
4. "Most likely failure mode you want to catch?" (header: `Failure mode`). Options: regression (was working), new feature edge case, silent error, performance.

**Round 2 (prerequisites + scope boundary), only if needed:**

1. "What state must exist before the test runs?" (header: `Prereqs`). Options: clean DB, seeded fixtures, specific records, services healthy.
2. "What's the boundary?" (header: `Boundary`). Options: just this feature, includes upstream, end-to-end including third-party.

Stop after round 2. If the spec is still ambiguous, ask the user to type a one-paragraph clarification and proceed with what they wrote.

### 2.6 Record the converged spec

Before writing the plan, paste back a 3-5 line summary of what you're about to build into:

- Subject:
- Acceptance criteria:
- Prerequisites:
- Identity scope:
- Failure mode being guarded:

This is for the user to sanity-check. If the user objects, loop back to whichever round resolved the wrong answer.

## Stage 3: pick runtime, phase, sequence number

### 3.1 Runtime

| Assertion shape | Runtime |
|---|---|
| HTTP endpoint contract (status, headers, JSON shape) | `hurl` when fixture-heavy, else `bash` + curl via `lib/api.sh` |
| Page rendering, DOM, navigation, forms | `agent-browser` |
| DB state, env presence, file presence, process lifecycle | `bash` |
| Background job processed within time | `bash` (polling) |
| Mixed (login + UI + DB check) | `bash` (helpers compose) |

When uncertain, bash. The lib helpers compose.

### 3.2 Phase + sequence number

Read `WARDEN_PHASES` from `.warden/warden.config.sh`. If a phase fits the spec (auth → matches an `auth` phase; UI → matches `frontend`), place there. Otherwise root of `.warden/plans/`.

```bash
PHASE_DIR=".warden/plans${PHASE:+/$PHASE}"
NEXT_NN=$(printf "%02d" $(( $(ls "$PHASE_DIR" 2>/dev/null | grep -oE '^[0-9]+' | sort -n | tail -1 || echo 0) + 1 )))
```

Slug the subject into kebab-case.

## Stage 4: write the plan

`Read` the matching template at `$PLUGIN_ROOT/templates/plan-bash.md`, `plan-hurl.md`, or `plan-browser.md` for style reference. Do not copy verbatim.

Required sections in the plan:

- `# <NN> - <Title>` heading
- `## What it proves` (one paragraph derived from converged spec)
- `## Prerequisites` (from converged spec)
- One or more `### Step` headings with bash blocks
- First bash block starts with `set -uo pipefail` and `source "$WARDEN_LIB/assert.sh"`
- Every check produces a `warden_pass` or `warden_fail` (see `references/antipatterns.md`)
- For multi-identity scenarios, use `warden_signin_as <slot>` and assert authorization via `warden_api_status_eq`

Write to `$PHASE_DIR/<NN>-<slug>.md`.

## Stage 5: report back

Tell the user:
- Path written
- Spec source used (artifact or interactive)
- Runtime chosen and why
- Phase placement
- One-liner to run it: `bash .warden/run.sh <NN>-<slug>`
- Any prerequisites that need to be satisfied before running

## Error paths

- `.warden/` exists but is corrupted (missing `run.sh` or `lib/`): tell the user, suggest `/warden:doctor` to inspect, do not silently overwrite.
- Multiple ambiguous spec sources and the user picks one but the artifact is empty or unparseable: surface the issue, offer to fall back to interactive Q&A.
- User abandons interactive Q&A mid-stream (skips all questions, or cancels): stop and report. Do not write a plan from incomplete spec.
