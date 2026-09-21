---
name: tower
description: "Run the orchestrator's war room on visible Herdr panes so the user can watch every child agent work. Use when the user says 'tower on', 'orchestrate this in herdr', wants routed agents they can see, or when the orchestrator is on inside a Herdr-managed pane."
---

# Tower

The orchestrator skill decides who does what. This skill decides where they run:
one Herdr pane per child, visible to the user, instead of invisible background
subagents.

Gate first:

```bash
test "${HERDR_ENV:-}" = 1
```

If the check fails, say the session is not inside Herdr and fall back to the
orchestrator's own substrate. Do not run any `herdr` command.

## Commands

- `tower on` — orchestrator mode with this substrate. Loads `orchestrator` and
  `herdr` if they are not already in context.
- `tower off` — same as `orchestrator off`.
- `tower status` — the orchestrator status check, with pane states from Herdr.

## What stays the same

Everything the orchestrator skill defines: the three slots, personas, routing
rules, the delegation brief, the war room table, the stall cap, and the safety
rules. Read them there. This file replaces only the "Child Agent Substrate"
section. The `herdr` skill remains the authority for CLI syntax and safety.

## Substrate mapping

| Orchestrator step | Tower |
| --- | --- |
| Spawn a child | `pane split` (or `tab create` for an executor), then `agent start <name> --kind claude --pane <id>` |
| Continue a child | `agent prompt <name> "<text>" --wait --timeout <ms>` |
| Status check | `agent list`; per child `agent get <name>` |
| Read a closeout | `agent read <name> --source recent-unwrapped --lines 200` |
| Worktree isolation | `worktree create --branch <name>` for the executor's workspace |
| Stall | `agent_status` unchanged across two status checks |

### Naming

The agent name is the war room key: `<branch-or-key>-<slot>`, lowercase,
hyphens, under 32 chars. `auth-exec`, `auth-audit`, `search-survey`. The name
follows the pane occupant, so the same child answers follow-up prompts on that
branch, and `agent list` reads as the roster.

### Placement

- Surveyors and auditors are short-lived: split beside the calling pane with
  `--no-focus`, right when wide, down when tall, and close the pane after the
  closeout is recorded.
- Executors are long-lived and own a branch: give each its own tab, labelled with
  the branch, so its transcript is not fighting for space. Use a worktree
  workspace when two executors are mutating at once.
- Never create a workspace, tab, or pane the user did not ask for beyond these
  rules, and never close one this session did not create.

### Dispatch

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
herdr agent start auth-exec --kind claude --pane <returned-pane-id>
herdr agent prompt auth-exec "<delegation brief>" --wait --timeout 600000
```

Wait for `agent start` to return ready before prompting. The delegation brief is
the orchestrator's, verbatim, plus one line: "Finish your closeout as a short
Markdown block so it can be read from the terminal."

### Waiting

`agent prompt --wait` blocks this session on one child. With several children
active, put each wait in a background Bash call, or prompt without `--wait` and
use `agent wait <name> --timeout <ms>` at the next status check. A timeout does
not prove the prompt was lost; read the pane before re-sending.

### Blocked children

A child in `blocked` has a permission dialog or a question on screen. Do not
answer it. Report the row as blocked, name the pane so the user can look, and
route the decision to the user. This is the visibility the substrate exists for.

### Reading results

Read the closeout with `agent read`. If the transcript is longer than the read
returns, ask the child to write the closeout to a Markdown file in a temporary
directory and reply with the path, then read that file. Findings from surveyors
and auditors still come back to this session, and this session routes any fix to
the owning executor.

### War room table

Same four columns. Put the agent name in the Next cell on the first row for a
branch so it survives summarization:

```md
| auth | executor (backend) | working | pane auth-exec: migration in progress |
```

## Success criteria

- `tower on` inside Herdr yields a war room where every child is a visible pane.
- Outside Herdr it degrades to the orchestrator's own substrate with one line of
  notice.
- Same-branch follow-ups go to the same named agent.
- A blocked child reaches the user, not an automatic answer.
- Nothing in `orchestrator` or `herdr` is duplicated here beyond the table above.
