---
description: Generate FLOW.md — human verification steps for the active sprint's acceptance predicates. Thinks like a tester; where to log in, what to click, which route to visit. Prioritizes predicates machines couldn't sense. Middleware between features/ and warden design.
allowed-tools: Bash, Read, Write, Glob, Grep
argument-hint: [--plan N]
---

Translate the active sprint's acceptance predicates into steps a human can walk. Not a test harness — a walkthrough. The reader is a person with a browser, a terminal, and no context.

## Position in the loop

Three sensors cover one goal set (`features/*.feature`): nyquist senses machine-testable predicates during execute; **flow is the human sensor** — it tells a person how to observe the rest; warden senses deterministically post-sprint. Flow's output also feeds `/warden:design` (Prerequisites, Identity scope).

## Steps

1. **Locate the active sprint:** `slug=$(cat .jira/CURRENT)`. If empty or missing, stop.

2. **Read the sources:**
   - `.jira/sprints/<slug>/features/*.feature` — the predicates (required; if missing, stop and point at `/jira:plan`)
   - All `*-PLAN.md` — implementation context per predicate (via `effects:`); `--plan N` narrows to one plan's predicates
   - `CONTEXT.md` — locked decisions that shape expected behavior
   - `EXECUTION.md` `## Nyquist results` block, if present — which predicates are already machine-sensed

3. **Classify each predicate:**
   - `machine-sensed` — a nyquist results line carries its ID with a green test
   - `human-required` — marked `not_testable_in_code` / `covered-by-inspection`, or no nyquist line at all
   - If EXECUTION.md doesn't exist yet (pre-execute), every predicate is `human-required`

4. **Write `.jira/sprints/<slug>/FLOW.md`:**

   ```markdown
   ---
   sprint: <slug>
   generated: <iso date>
   predicates: <total> (<human-required count> need human sensing)
   ---

   # Flow: <sprint goal>

   ## Before you start

   Services to run, accounts to use, data that must exist — concrete: the command
   that starts the server, the exact login email/role (never a password — reference
   where it's shared), the seed state.

   ## Verify by hand (predicates machines could not sense)

   ### TOK-02 — <scenario title>
   1. Log in as <role> at <route>
   2. <do the Given — set up the precondition>
   3. <do the When — the action, exact button/route/command>
   4. **Expect:** <the Then, observably — what you see when it holds, and what
      failure would look like>

   ## Already machine-sensed (spot-check optional)

   ### TOK-01 — <scenario title> — sensed by `tests/auth.test.ts`
   One-line human spot-check, for skeptics.
   ```

   Order: human-required predicates first, machine-sensed last. Every step names concrete UI/routes/commands — "press the Save button on /settings", never "verify the feature works". Steps derive from the scenario's Given/When/Then plus the claiming plan's files and actions.

5. **Report:** path written, predicate counts (human-required vs machine-sensed), and the follow-on: `/warden:design` consumes FLOW.md's prerequisites when designing acceptance plans.

## Hard rules

- **Read-only on everything except FLOW.md.** No test files, no scripts, no harness — warden owns executable acceptance.
- **Re-runnable.** Overwrite FLOW.md wholesale each run; it's derived state, never hand-edited.
- **No internal jargon in the steps themselves** — a contractor or client tester should be able to follow them cold. Predicate IDs appear as section anchors (internal doc, sprint-scoped), but each step is plain English.
- **Never invent behavior.** Every Expect line traces to a scenario's Then clause or a locked decision. If a predicate's expected behavior is ambiguous, say so in the step rather than guessing.
- **No credentials.** Reference where they were shared, never the values.
