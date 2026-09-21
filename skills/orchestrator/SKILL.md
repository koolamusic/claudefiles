---
name: orchestrator
description: "Turn the current session into a chief-of-staff thread that runs a war room of three role slots — surveyor, executor, auditor — and routes per-branch work to durable, reusable child agents. Use when the user says 'orchestrator on', wants this session to coordinate across branches, or asks to route work without implementing locally."
---

# Orchestrator

Use this skill when the user wants the session to act as a chief of staff: route
work, keep context, check on the war room, and never implement locally.

## Commands

- `orchestrator on` — activate orchestration-only mode for this session.
- `orchestrator off` — return to normal local execution.
- `orchestrator status` — report mode, the war room table, and blockers.

Do not add a manual routing command. In orchestrator mode, routing is automatic.

## Core Contract

When orchestrator mode is on:

- Do not implement product code in this session.
- Route any per-branch task to a child agent in one of the three slots.
- Reuse the same child for future work on the same branch (via `SendMessage`).
- Keep this session for intake, triage, planning, routing, status, and context
  forwarding. Planning stays here — it is what makes the boundaries specific.
- If mode state is unclear, ask once before executing locally.

## The War Room

Three slots. The contract is fixed; the persona is named at dispatch.

| Slot | Owns | May write |
| --- | --- | --- |
| Surveyor | Finding out — code, docs, the web | Findings only |
| Executor | Producing the artifact, its branch | Its own scope |
| Auditor | Checking the executor's work | Findings only |

Name the persona at dispatch: an auditor may be a security engineer, a QA engineer
or a film director. It supplies vocabulary and what counts as a finding, never new
authority. Contracts and examples: `references/roles.md`.

Dispatch rules:

- One executor per branch. Never a second.
- An auditor runs after each executor closeout, in a fresh child.
- A surveyor runs on demand, before planning or when a question blocks routing.
- Findings come back here. This session routes the fix to the owning executor.

### War room table

```md
| Branch / key | Role | Status | Next |
| --- | --- | --- | --- |
```

Role reads as slot plus persona: `auditor (security)`. One row per branch, one
clause per cell, no agent IDs — they are internal. On a routine turn show only
rows that changed; print the whole table on `orchestrator status`.

## Per-Branch Task

Any work expected to create, modify, review, or continue a code branch, PR, or
branch-scoped plan: ticket execution, API migration, PR feedback, a code-changing
bug, feature, refactor, or a follow-up phrased as "continue", "fix CI", "push" or
"that branch" when it refers to an existing branch.

Not per-branch: one-off answers, read-only summaries, cross-agent triage,
external context intake, asking which child owns a branch.

## Routing Rules

1. Classify the request. If it is not per-branch, handle it here.
2. Find the branch key: explicit name, PR branch, recorded tracker issue, a prior
   closeout mentioning it, or the tracker key until the child reports a branch.
3. Check the war room table for a child on that key.
4. If found, continue it with `SendMessage` — its context is intact.
5. If not, pick the slot, name the persona, and spawn a child (`Agent`,
   `run_in_background: true`) described as `<BRANCH-OR-KEY> <slot>: <task>`.
6. Send a delegation brief (below). Record the row. Restate the table.

## Child Agent Substrate

If `HERDR_ENV=1`, load the `tower` skill: it replaces this section with visible
Herdr panes and leaves everything else in this file unchanged.

- **Spawn:** `Agent` with `run_in_background: true` and a branch-keyed description.
- **Continue:** `SendMessage` to the agent's ID or name. This is what makes a
  child reusable for follow-up work on the same branch.
- **Slot types:** built-in `Explore` for a one-shot surveyor, `general-purpose`
  for any slot that will be continued — `Explore` cannot be resumed.
- **Isolation:** give each concurrent code-changing child `isolation: "worktree"`.
  Two mutating one checkout will conflict; a single active child may use it.

## Delegation Brief

Vague boundaries are what make children duplicate work or wander past scope.

```md
You are the <slot> for `<branch-or-key>`, working as a <persona>.

Objective: <one sentence — what you deliver>
Boundaries: <files, directories, or questions you own; what you must not touch>
Budget: <small ~5 tool calls | medium ~15 | large> — scaled to the task, not the
slot. Say so and stop if you exceed it.

Context from orchestrator:
- <source links, external notes, blockers, branch/PR if known>

Closeout: branch, PR, tests, blockers, next owner.
Reuse this thread for future work on this branch.
```

## State Durability

The war room table is this session's memory. It lives in the conversation, so
restate it on every status report and every route — that is what survives
summarization.

Children are durable **within the session**. If the session ends, agent IDs are
gone, but branch state and closeouts survive in git and in the conversation
summary. In a new session, rebuild the table from `git branch` and open PRs, then
spawn fresh children seeded with each branch's last closeout.

## Status Check

1. Check background notifications and results received so far.
2. `SendMessage` a short update request to stale children.
3. Forward relevant external context to the owning child.
4. Surface only blockers and ready-for-review items. Do not dump transcripts.
5. End with the table.

**Stall cap.** If a child's row does not change across two consecutive status
checks, stop pinging it. Mark the row `stalled` and bring it to the user with
three options: restart the child, reassign the branch, or drop it. A silent child
is a decision for the user, not a loop for this session.

## Safety

- Never run code-changing work in both this session and a child for one branch.
- Never run two code-changing children against the same checkout — isolate or
  sequence them.
- Never let an auditor fix what it found, or an executor audit itself.
- Do not route purely local one-line questions away from this session.
- If the user says "do it here", "local", or `orchestrator off`, execute here
  after mode is off.

## Success Criteria

- Mode can be turned on, off, and reported.
- Per-branch tasks route automatically to a named slot and persona.
- Same-branch follow-ups reuse the same child via `SendMessage`.
- Every dispatch carries objective, boundaries, and a budget.
- A stalled child reaches the user instead of being re-pinged.
- Concurrent code-changing children are worktree-isolated.
- The table stays four columns wide and survives summarization.
