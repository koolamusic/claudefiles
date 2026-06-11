# Why this skill exists

Long coordination sessions rot in a predictable way: the session that was
supposed to track five branches starts implementing one of them, burns its
context on diffs and test output, and loses the cross-branch picture. Then
follow-up work on a branch lands in whatever session is open, with none of the
prior context. This skill makes the split explicit — one coordination thread
that never implements, one durable child agent per branch that keeps its
context across follow-ups.

## Provenance

Ported from a Codex skill (`.reference/skills/orchestrator`, originally built
on `codex_app.*` thread tools). The port is not faithful, deliberately:

- **Child threads → background agents.** Codex sub-agents are single-shot, so
  the original forbade them and required durable thread tools. Claude Code
  agents *are* continuable (`SendMessage`), which is exactly the
  reusable-child semantic the skill wants. Caveat documented in the skill:
  durability is per-session, not cross-session.
- **No-worktree rule inverted.** The original forbade worktrees because Codex
  children shared one checkout. In Claude Code, concurrent code-changing
  agents on one checkout *will* conflict — worktree isolation is the correct
  default, so the skill requires it for concurrent children.

## Relation to `spawn`

They coexist. `spawn` is finite, wave-based fan-out: decompose a plan, dispatch
parallel units, integrate, done. `orchestrator` is a long-lived *mode*: the
session stays up as a router and the same child keeps owning its branch across
many requests. Use `spawn` to parallelize one body of work; use `orchestrator`
to run a desk.
