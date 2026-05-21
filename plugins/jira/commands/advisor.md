---
description: "Advisory gate for triage or plan decisions. Spawns a second-opinion agent that challenges assumptions, surfaces risks, and proposes alternatives before the decision commits. Based on Anthropic advisor tool pattern."
allowed-tools: Bash, Read, Glob, Grep, Agent, AskUserQuestion
argument-hint: "<triage|plan> [--sprint <slug>]"
---

Get a second opinion before committing to a triage decision or plan. The advisor is an independent agent that reads the same artifacts but approaches them from a skeptical stance.

## Parse the input

`$ARGUMENTS`:
- `triage` — advise on a triage recommendation (issue labels, state transition, agent brief)
- `plan` — advise on sprint plans (wave structure, task decomposition, risk coverage)
- `--sprint <slug>` — target a specific sprint (default: active)

If empty, infer from sprint state:
- If plans exist but no EXECUTION.md: assume `plan`
- If no plans: assume `triage`
- If ambiguous: ask

## Context gathering

### For triage advisory

Read:
- The issue under triage (from `gh issue view` or the sprint's BRIEF.md)
- Any existing triage notes or comments
- `.jira/STATE.md` — prior sprint patterns and decisions log
- `.project/PROJECT.md` — project-level goals (does this issue align?)
- `.project/ROADMAP.md` — is this the right time for this work?

### For plan advisory

Read:
- All `*-PLAN.md` files in the sprint
- `CONTEXT.md` — locked decisions
- `RESEARCH.md` — original research findings
- `BRIEF.md` — the original problem statement

## Spawn the advisor agent

Single `Agent` call with the `jira-advisor` agent:

```
You are the advisor — an independent reviewer challenging the current <triage|plan> recommendation.

## Your inputs
<all gathered context>

## Your job
Produce a structured advisory with three sections:

1. **Challenges** — assumptions in the <recommendation|plan> that might be wrong. For each:
   - What's assumed
   - Why it might not hold
   - What breaks if it doesn't
   - Severity: BLOCKER / RISK / MINOR

2. **Alternatives** — different approaches the <triage|planner> didn't consider. For each:
   - What it is
   - What it costs vs the current approach
   - When you'd pick it over the current approach

3. **Endorsements** — parts of the <recommendation|plan> that are solid. Don't manufacture criticism for things that hold up.

## Rules
- Be specific. "This might not scale" is noise. "The N+1 query on line 45 of 02-PLAN.md will timeout with >1000 entries because..." is signal.
- Reference artifacts by path and section.
- Don't rewrite the plan. Challenge it.
- If everything looks solid, say so in 3 lines. Don't pad.
```

## Process the advisory

1. **Read the advisor's output.**

2. **If any BLOCKER findings:** surface them via `AskUserQuestion`:
   - Revise the plan/triage to address blockers
   - Proceed anyway (user overrides — log the override in CONTEXT.md)
   - Re-research (route back to `/jira:research`)

3. **If only RISK/MINOR findings:** present them as information. The user decides whether to act on each.

4. **Persist the advisory:**
   - For plan: `.jira/sprints/<slug>/ADVISORY.md`
   - For triage: append to the issue as a comment (with AI disclaimer header)

5. **Commit if persisted to disk:**
   ```bash
   git add .jira/sprints/<slug>/ADVISORY.md
   git commit -m "advisor(<slug>): <verdict summary>"
   ```

## Hard rules

- **Never modify plans or triage directly.** The advisor reports; the user or planner acts.
- **Blockers are gates.** Don't proceed past a BLOCKER finding without explicit user override.
- **Don't invoke the advisor automatically.** This is opt-in — the user calls `/jira:advisor` when they want a second opinion.
- **One advisory per invocation.** Don't loop — if the user wants to re-advise after changes, they invoke again.
