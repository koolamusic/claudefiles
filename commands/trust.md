---
name: trust
allowed-tools: Bash($HOME/.claude/hooks/trust-monitor.sh:*)
description: Award, deduct, or inspect the session agent's trust ledger
---

## Context

- Current standing: !`$HOME/.claude/hooks/trust-monitor.sh status`
- Recent events: !`$HOME/.claude/hooks/trust-monitor.sh log | tail -5`

## Your task

Parse `$ARGUMENTS` and run the matching CLI call. This command is the user's
pen on the ledger — the `by=user` channel. You never award yourself points
outside this command, and only the user's explicit invocation counts.

| Arguments | Run |
|---|---|
| `+N <reason>` or `award N <reason>` | `trust-monitor.sh award N "<reason>"` |
| `-N <reason>` | `trust-monitor.sh deduct N "<reason>"` |
| `<class> <reason>` where class is minor, delivery, unverified, drift, fabrication, tamper | `trust-monitor.sh deduct <class> "<reason>"` |
| `status` or empty | report the Context section above, no calls |
| `log` | `trust-monitor.sh log` |

Fibonacci deduction classes: minor −2, delivery −5, unverified −8, drift −8,
fabrication −13, tamper −21. Self-reports (−3) are not made through this
command — the agent runs `trust-monitor.sh self-report` directly, unprompted,
when it catches its own violation.

After the call, report the new score and level in one line. If the score
crossed below the termination floor, state plainly that the agent is
terminated and the user can `/clear` for a fresh L2 agent.

No commentary, no self-defense when deducted. The ledger speaks.
