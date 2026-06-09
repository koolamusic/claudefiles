# Phase sequence

Plans run in the order declared by `WARDEN_PHASES` in `warden.config.sh`.
This file is the human prose explaining why that order, and what each
phase seeds for the next. The phases array is the executable contract;
this file is the rationale a contributor reads first.

If you reorder phases here, update `WARDEN_PHASES` to match.

## Phase 1: <phase-slug>

**What it proves:** what shipping looks like for this slice.

**Seeds for next phase:** rows in the database, files on disk, sessions
cached, tokens minted. Anything subsequent phases assume.

## Phase 2: <phase-slug>

**What it proves:**

**Seeds for next phase:**

## State carried across phases

Document the long-lived test artifacts: a single seeded user, a session
cookie cached in the env, MCP tokens, fixture files. Subsequent phases
assume these exist; they should not be re-created.

- Email: `$INITIAL_USERNAME` (sourced from `.env` via `warden_load_env`)
- Password: `$INITIAL_PASSWORD`
- Session: created in Phase 1, reused across all subsequent plans

## Clean slate

To reset everything and start fresh (destructive):

```bash
# Example for a Postgres-backed app. Adapt to your stack.
# psql -h 127.0.0.1 -U postgres -d <db> -c "
#   DELETE FROM <ephemeral_tables_in_dependency_order>;
# "
```
