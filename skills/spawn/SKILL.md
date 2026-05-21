---
name: spawn
description: "Fan out work to parallel sub-agents with worktree isolation. Reads a plan, scope list, or inline description, breaks it into waves of independently-dispatchable units, and orchestrates execution. The orchestrator never implements — it coordinates. Use when user says 'spawn', 'fan out', 'parallelize this', 'orchestrate', or has multiple independent tasks to dispatch."
argument-hint: "<plan path, scope description, or 'auto' to read active sprint>"
---

# Spawn

Dispatch parallel sub-agents with isolation guarantees. You are the orchestrator — you coordinate, delegate, track, and integrate. You never write application code yourself.

## Input

`$ARGUMENTS` is one of:

- **A file path** — read it as the scope document (PLAN.md, HANDOFF.md, a GitHub issue, any structured doc)
- **Inline text** — treat it as the scope description directly
- **`auto`** — look for `.jira/CURRENT` and read the active sprint's plans. If no sprint, check `.project/ROADMAP.md` for the next unstarted phase. If neither exists, ask.
- **Empty** — ask via `AskUserQuestion` what work to dispatch

## Process

### 1. Parse scope into units

Read the input and decompose into **spawn units** — independently executable chunks of work. Each unit must have:

- **ID** — short label (A, B, C or descriptive slug)
- **Objective** — one sentence: what this agent delivers
- **Inputs** — files to read, context to pass
- **Outputs** — files to create/modify, commits expected
- **Depends on** — other unit IDs that must complete first (empty = wave 1)

### 2. Build the wave map

Group units into waves by dependency:

```
Wave 1: [A, B, C]  — no dependencies, run in parallel
Wave 2: [D]         — depends on A
Wave 3: [E, F]      — depends on D
```

Units within a wave touch disjoint files. If two units in the same wave would modify the same file, split the wave or merge the units.

### 3. Present the dispatch plan

Show the user:

```
## Dispatch Plan

**Total units:** N across W waves
**Isolation:** worktree / same-tree (recommend worktree if >1 unit per wave)

| ID | Wave | Objective | Depends on | Est. complexity |
|---|---|---|---|---|
| A | 1 | ... | — | small |
| B | 1 | ... | — | medium |
| C | 2 | ... | A | small |

Proceed?
```

Wait for explicit approval. The user may reorder, merge, split, or cancel units.

### 4. Execute wave-by-wave

For each wave in order:

**a. Spawn agents in parallel.** Single message, one `Agent` tool call per unit in the wave. Each agent gets:

```
You are sub-agent <ID> in a spawn dispatch.

## Your objective
<objective>

## Context
<brief from scope doc + any outputs from prior waves>

## Files you own
<list of files this agent may create/modify — no others>

## Constraints
- Commit your work with a descriptive message
- Do NOT push to remote
- Do NOT open PRs
- Do NOT modify files outside your scope
- If blocked, commit what you have and report the blocker
```

**Isolation decision:**
- If wave has >1 unit: use `isolation: "worktree"` on each Agent call
- If wave has 1 unit: foreground without worktree (simpler)
- User can override in the dispatch plan approval step

**b. Collect results.** When all agents in the wave return:

- Read each agent's reported status
- Run `git log --oneline -5` (or per-worktree equivalent) to verify commits landed
- If any agent reports a blocker: surface it via `AskUserQuestion` — retry, skip, or abort
- If any agent's worktree has changes: note the worktree branch for integration

**c. Integrate worktree results** (if using worktrees):

- For each completed worktree agent, cherry-pick or merge its commits onto the working branch
- Resolve conflicts if any — surface to user if non-trivial
- Verify the integrated state compiles / passes basic checks

### 5. Report

When all waves complete:

```
## Spawn Complete

**Units dispatched:** N
**Waves executed:** W
**Status:**
| ID | Status | Commits | Notes |
|---|---|---|---|
| A | complete | abc1234 | — |
| B | complete | def5678 | — |
| C | blocked | — | <blocker description> |

**Integration:** all cherry-picked onto <branch>
**Next step:** <recommendation — run tests, open PR, continue with next spawn>
```

## Hard rules

- **You are the orchestrator.** Never write application code, tests, or configuration yourself. Your job is dispatch, tracking, and integration.
- **Wave-safe parallelism.** Never dispatch two agents that modify the same file in the same wave.
- **Foreground parallel, not background.** Use multiple Agent calls in a single message for within-wave parallelism. Background agents have worktree isolation issues.
- **Never force-push.** If integration has conflicts, surface and ask.
- **Never auto-merge PRs.** Open them, report them, stop.
- **Git state verification after every wave.** Don't trust agent self-reports alone — check `git log` and `git status`.
- **User approval before dispatch.** Always show the dispatch plan and wait for "go."

## Integration with jira

When invoked by `jira:execute` or with `auto` argument in a jira-managed repo:

- Read wave structure from `*-PLAN.md` frontmatter (plans already have `wave:` fields)
- Pass CONTEXT.md (locked decisions) to every agent
- Write integration results to EXECUTION.md (append-only)
- Don't duplicate jira:execute's Nyquist/verifier gates — those run after spawn returns

## Integration with studio

If `.workspacerc` exists, resolve all `.jira/` and `.project/` paths through the workspace. Worktree agents don't get symlinks automatically — pass resolved absolute paths in agent prompts.
