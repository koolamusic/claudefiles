---
name: orchestrator
description: "Turn the current session into a coordination thread that routes per-branch implementation work to durable, reusable child agents. Use when the user says 'orchestrator on', wants this session to act as chief-of-staff across branches, or asks to route work without implementing locally."
---

# Orchestrator

Use this skill when the user wants the current session to act as a chief-of-staff
thread: route work, keep context, check on child agents, and avoid doing
implementation locally.

## Commands

- `orchestrator on` — activate orchestration-only mode for this session.
- `orchestrator off` — return to normal local execution.
- `orchestrator status` — report mode, active child agents, known branch keys,
  and blockers.

Do not add a manual routing command. In orchestrator mode, routing is automatic.

## Core Contract

When orchestrator mode is on:

- Do not implement product code in this session.
- Automatically route any per-branch task to a child agent.
- Reuse the same child agent for future work on the same branch (via `SendMessage`).
- Keep this session for intake, triage, routing, status, summaries, and context
  forwarding.
- If mode state is unclear, ask once before executing locally.

## Per-Branch Task

A per-branch task is any work that is expected to create, modify, review, or
continue a code branch, PR, or branch-scoped implementation plan.

Examples:

- Ticket or issue execution.
- API migration work.
- PR feedback resolution.
- Code-changing bug, feature, refactor, or migration.
- Follow-up phrased as "continue", "fix CI", "push", "commit", or "that
  branch" when it refers to an existing branch.

Not per-branch by default:

- One-off answers.
- Read-only status summaries.
- Cross-agent triage.
- External context intake.
- Asking which child agent owns a branch when the mapping is missing.

## Routing Rules

1. Classify the request.
2. If it is not per-branch, handle it in the orchestrator session.
3. If it is per-branch, find the branch key:
   - explicit branch name
   - PR branch
   - tracker issue branch already recorded
   - prior child agent status mentioning the branch
   - if no branch exists yet, use the tracker/workstream key until the child
     creates and reports the branch
4. Check the branch table for an existing child agent for that branch key.
5. If found, continue that agent with `SendMessage` — its context is intact.
6. If not found, spawn a new child agent (`Agent` tool, `run_in_background: true`)
   with a description like `<BRANCH-OR-TICKET> <short task title>`.
7. Tell the child exactly what skill/request to run and include the source
   context the orchestrator already gathered.
8. Ask the child to report its branch key, PR URL, test results, blockers, and
   next owner in its closeout.
9. Record the mapping in the branch table and restate the table in your status
   output (see State Durability).

## Branch Table

```md
| Branch / key | Child agent (id or name) | Status | Last update | Next |
| --- | --- | --- | --- | --- |
```

## Child Agent Substrate

Child agents are Claude Code background agents:

- **Spawn:** `Agent` tool with `run_in_background: true` and a branch-keyed
  description.
- **Continue:** `SendMessage` to the agent's ID or name — this is what makes a
  child reusable for follow-up work on the same branch.
- **Isolation:** when two or more children run code-changing work at the same
  time, give each `isolation: "worktree"`. Two agents mutating one checkout on
  different branches will conflict. A single active child may work in the main
  checkout.

## State Durability

The branch table is the orchestrator's memory. It lives in the conversation,
so:

- Restate the full table every time you report status or route new work. This
  keeps it alive through context summarization.
- Child agents are durable **within the session**. If the session ends, agent
  IDs are gone — but branch state and child closeout reports survive in git and
  the conversation summary. In a new session, rebuild the table from `git branch`
  / open PRs and spawn fresh children seeded with each branch's last closeout.

## Child Prompt Shape

When creating or reusing a child agent, send a compact prompt:

```md
You are the child execution agent for `<branch-or-ticket>`.

Run: <exact user skill/request>

Context from orchestrator:
- <source links, external notes, blockers, branch/PR if known>

Rules:
- Reuse this thread for future work on this branch.
- If code changes, follow repo branch/PR rules.
- Report branch, PR, tests, blockers, and next owner in your closeout.
```

## Status Check

On `orchestrator status` or when the user asks how things stand:

1. Check background agent notifications and results received so far.
2. `SendMessage` a short update request to stale children.
3. Forward relevant external context to the owning child.
4. Surface only actionable blockers and ready-for-review items to the user.
5. Keep the status short; do not dump child transcripts. End with the branch
   table.

## Safety

- Never run code-changing work in both the orchestrator and a child for the
  same branch.
- Never run two code-changing children against the same checkout at the same
  time — use worktree isolation, or sequence them.
- Do not route purely local one-line questions away from the orchestrator.
- If the user says "do it here", "local", or `orchestrator off`, execute in the
  current session after mode is off.

## Success Criteria

- Orchestrator mode can be turned on, off, and reported.
- Per-branch tasks are routed automatically.
- Same-branch follow-ups reuse the same child agent via `SendMessage`.
- Concurrent code-changing children are worktree-isolated.
- The branch table survives status checks and summarization.
- The orchestrator remains a coordination thread, not an implementation thread.
