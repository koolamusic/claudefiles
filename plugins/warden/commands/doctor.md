---
description: "Health check for the project's `.warden/` setup. Surfaces engine drift, lib gaps, missing runtimes, malformed audit trail, gitignore mistakes, plan-format issues. Reports findings; asks the agent to walk the user through fixes interactively."
allowed-tools: Bash, Read, Grep, Glob
argument-hint: ""
---

Run a full health check on `.warden/`. Print a structured report grouped by area. Findings are tagged `ok`, `advisory` (informational; nothing broken), or `error` (will or already does cause failures).

This command does NOT auto-fix anything. Drift between the project's runner and the plugin template is project-owned and expected; the user decides whether to sync. Missing runtimes, broken config, and malformed artifacts are the user's call too. After the report, offer to walk through whichever items the user wants resolved.

## Precondition

```bash
if [ ! -d .warden ]; then
  echo "No .warden/ in this project. Run /warden:design to bootstrap."
  exit 1
fi
```

## Checks

Run each check, collect findings. Use `Read` and `Glob`/`Grep` for inspection, `Bash` for parsing.

### Engine integrity

- `.warden/run.sh` present? Record the version stamp from its first comment line if present.
- `.warden/lib/` present and contains all 10 expected files: `assert.sh`, `audit.sh`, `auth.sh`, `api.sh`, `db.sh`, `browser.sh`, `hurl.sh`, `env.sh`, `wait.sh`, `parse.sh`. List any missing.
- Bash syntax: `bash -n` on `run.sh` and every `lib/*.sh`.

### Engine drift vs plugin template

For `run.sh` and each `lib/*.sh`, diff against `${CLAUDE_PLUGIN_ROOT}/templates/run.sh` and `${CLAUDE_PLUGIN_ROOT}/templates/lib/<name>.sh`. Report:

- Files that match the template byte-for-byte: ok.
- Files that differ: advisory with a line-count summary (`run.sh: 3 added, 1 removed vs template`). Do not include the diff body inline; offer to show the full diff if the user asks.
- Files in `.warden/lib/` with no counterpart in the template: advisory ("project-specific lib helper").
- Files missing from `.warden/lib/` that the template ships: error.

Frame drift as expected and project-owned. The runner being a thin bash script that survives plugin uninstall is the whole point; drift is a feature, not a bug.

### Config

Source `.warden/warden.config.sh` in a subshell. Verify:

- The file is sourceable (`bash -n` clean and no errors when sourcing into a fresh subshell with `set -u`).
- `WARDEN_PHASES`, `ENV_FILES`, `PREFLIGHT`, `RUNTIME_CHECKS`, `DESTRUCTIVE` are all defined (the runner pre-declares them, but a custom config could break this if rewritten).
- If `WARDEN_AUTH_STRATEGY` is set:
  - `cookie-session`, `jwt-bearer`, `jwt-cookie`: `WARDEN_AUTH_SIGNIN_URL` must be set. Missing → error.
  - `jwt-bearer`: optional `WARDEN_AUTH_TOKEN_PATH` (default `.token`).
  - `api-key`: optional `WARDEN_AUTH_HEADER` (default `X-API-Key`) and `WARDEN_AUTH_TOKEN_ENV` (default `AUTH_API_KEY`).
  - `custom`: `WARDEN_AUTH_CUSTOM` must point at a readable script.
- If `WARDEN_USERS_<slot>_email` is set, the matching `_password` must also be set, and vice versa.

### Phases vs SEQUENCE.md vs plans/

- For each phase in `WARDEN_PHASES`, `.warden/plans/<phase>/` should exist and contain at least one `*.md` file. Missing dir → advisory. Empty dir → advisory.
- Parse `.warden/SEQUENCE.md` for `## Phase N: <slug>` headers. Compare the slugs against `WARDEN_PHASES`. Drift between them → advisory (SEQUENCE.md is prose for humans; WARDEN_PHASES is executable). Suggest reconciling them.
- Plans at root of `.warden/plans/*.md` always run first per the runner; surface this if it surprises (e.g. a stray plan at root when the user expected phase-only execution).

### Engine dependencies

Warden's runner and lib rely on a small set of host tools. Even if no plan exercises them yet, missing engine deps silently produce broken artifacts (e.g. `audit.sh` skips JSONL emission when `jq` is missing, so `/warden:triage` then reports "no failures" against an empty audit trail).

Check, in order:

- `jq` present (`command -v jq`). Required by `lib/audit.sh` for every assertion. Missing → error.
- `curl` present. Required by `lib/auth.sh`, `lib/api.sh`, and any HTTP wait. Missing → error.
- `bash` major version ≥ 4 (`bash --version`). Lower → error; arrays, `[[ ]]` semantics, and `${!var}` indirection all break on bash 3 (the default `/bin/bash` on macOS without Homebrew). The runner advertises `#!/usr/bin/env bash`, so brewing bash and putting it first on PATH is the fix.
- macOS and Linux are the primary targets. On other platforms (Windows Git Bash, BusyBox), flag as advisory: untested.

### Runtime availability

For each runtime that plans actually use, check the tool is on PATH.

Detect which runtimes are in use by globbing plans and grepping for sourced libs:

- `jq`: always required if any plan sources `assert.sh` (the JSONL emit uses it). Missing → error.
- `hurl`: required if any plan sources `hurl.sh` or contains `warden_hurl_test`. Missing → error.
- `npx agent-browser`: required if any plan sources `browser.sh` or contains `warden_browser_*`. Missing → error.
- `psql`: required if any plan sources `db.sh` or contains `warden_psql_*`. Missing → error.
- `curl`: required if any plan sources `auth.sh`/`api.sh` or contains `warden_authed_curl`. Missing → error.

Also run each entry in `RUNTIME_CHECKS` from config. Failures → error (the user explicitly declared these as required).

### Audit trail

- `runs/asserts.jsonl`: every line parses as JSON (`jq -e -c .` per line). Count records, distinct runs.
- `runs/observations.jsonl`: same shape check. Count records.
- `runs/state`: each line matches `^[A-Za-z_][A-Za-z0-9_]*=.*$`. Malformed lines → advisory (the runner is tolerant).
- Any plan file that contains `warden_pass`/`warden_fail`/`warden_skip` but for which the JSONL has zero records → advisory: that plan has not been run yet against this audit trail.

### Gitignore

If `.gitignore` exists at project root:

- `.warden/logs/` should be ignored. Missing → advisory.
- `.warden/runs/` ignored is acceptable but may not be desired (the audit trail is most useful when committed). If `.warden/runs/` is ignored, advisory: "audit trail not committed; trend analysis will only show local runs."
- `.warden/plans/`, `.warden/fixtures/`, `.warden/lib/`, `.warden/run.sh`, `.warden/warden.config.sh`, `.warden/SEQUENCE.md`, `.warden/HANDOFF.md`, `.warden/remediation/` must NOT be ignored. Any of these in `.gitignore` → error.

### Plan format

Glob `.warden/plans/**/*.md`. For each:

- Has at least one fenced ```bash block. Missing → error (the runner will skip it as a no-op).
- The first ```bash block starts with `source` of `assert.sh` or contains a `warden_pass`/`warden_fail`/`warden_skip` call. Otherwise → advisory ("plan has no assertions; will run silently green").
- File matches the `NN-<slug>.md` naming convention. Off-convention → advisory.

## Output format

Print to stdout, grouped by area. Use this exact prefix convention:

- `  ok    <message>`
- `  advisory <message>`
- `  error <message>`

Then a final summary line: `Summary: N ok, M advisory, K error`.

If there are errors, print one or two suggested next steps inline (e.g. "Install hurl or remove api/02-flow.md").

Do not auto-show diff bodies or large dumps. Offer to expand them if the user asks.

## Conversation handoff

After the report, list any advisories or errors the user might want to walk through. Phrasing: "Want me to show the run.sh diff?", "Want to fix the gitignore?", etc. Each one is a small interactive task, not a separate command.

If everything is green, say so plainly and stop. No padding.
