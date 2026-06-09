---
description: "Brief the session from `.warden/HANDOFF.md` so a fresh agent or returning operator can pick up warden work cold."
allowed-tools: Read, Bash, Glob
argument-hint: ""
---

Resume warden work by reading the handoff document and the latest run, then briefing the user on current state.

## Precondition

```bash
if [ ! -f .warden/HANDOFF.md ]; then
  echo "No .warden/HANDOFF.md found. Run /warden:design to bootstrap, or /warden:triage to populate it from a recent run."
  exit 1
fi
```

## Read

- `.warden/HANDOFF.md`
- The most recent `.warden/runs/<id>.md` if any exist
- The list of files under `.warden/remediation/` if any

## Brief

Produce a single-pass summary:

1. **What this project is, in warden terms**: one sentence from the Stack section of HANDOFF.md.
2. **Auth strategy**: one line: which strategy, where the signin endpoint is.
3. **Last run**: run id, headline pass/fail counts. If no runs yet, say so.
4. **Open remediation**: count by priority, names of the P0/P1 items. Skip if empty.
5. **What's running**: quote the literal startup commands from HANDOFF.md so the user can paste them.
6. **Suggested next action**, one of:
   - "Stack isn't running. Boot it with the commands above and then `/warden:run`."
   - "Last run was green. Suggest `/warden:design` to add coverage for X."
   - "Last run had failures. `/warden:triage` will classify them."
   - "Open P0 remediation. The next move is fixing `<file>.md`."

Keep the brief under 10 lines. The point is to orient, not exhaustively dump state.
