# Handoff

> Session date: YYYY-MM-DD
> Context: one sentence on what state warden is in right now.

Read this first when resuming work after a context reset, a new machine,
or a new contributor onboards. `/warden:resume` reads this file and
briefs the new session.

## Current state

### Stack

- Service A: path, port, what it does
- Service B: path, port, what it does
- Postgres, Redis, or other infra

### What's running

```bash
# Commands to start the stack from cold
```

### Test credentials

- Email: `$INITIAL_USERNAME`
- Password: `$INITIAL_PASSWORD`
- Other tokens or secrets the suite needs

## Last run

Run with `bash .warden/run.sh` from project root.

- Backend phase: NN/MM passing
- Frontend phase: NN/MM passing
- Last run ID: see `.warden/runs/<id>.md`

## Open remediation

Failures tracked in `.warden/remediation/`. Format: `<NN>-<slug>.md`,
one file per failing scenario. `/warden:triage` writes these from a
failing run.

- [ ] Example remediation item: short description
