---
name: handoff
description: "Compact the current session into a handoff document for another agent or future session to pick up. Captures mission, repo state, role, scope, locked decisions, dispatch sequence, and a pickup checklist. Studio-aware. Use when pausing work, ending a session, switching contexts, or preparing for a fresh agent to continue."
argument-hint: "What will the next session focus on?"
---

# Handoff

Write a handoff document that lets a fresh agent continue this work cold. The reader has zero context from this conversation — the handoff is their entire briefing.

## Process

1. **Gather state.** Run these in parallel:
   - `git log --oneline -20` (recent commits)
   - `git status` (working tree)
   - `git branch --show-current` (active branch)
   - Check for `.jira/CURRENT` (active sprint)
   - Check for `.project/PROJECT.md` (project context)
   - Check for `.workspacerc` (studio workspace)

2. **Determine the output path.**
   - If `.workspacerc` exists: read the workspace path, write to `<workspace>/handoff.md`
   - If `.jira/` exists: write to `.jira/sprints/<active-slug>/HANDOFF.md`
   - Otherwise: write to the OS temp directory (`$TMPDIR` or `/tmp`)

3. **Write the handoff** using the structure below. If the user passed arguments, treat them as a description of what the next session will focus on and tailor accordingly.

4. **Don't duplicate.** Reference existing artifacts (CONTEXT.md, PLAN.md, RESEARCH.md, PRDs, issues) by path or URL. The handoff points to them — it doesn't restate them.

5. **Redact secrets.** Strip API keys, passwords, tokens, PII. If a secret is relevant context, note its purpose without the value.

## Handoff structure

```markdown
# Handoff — <date> — <one-line mission>

## Repo state
- **Branch:** <branch>
- **Clean:** yes/no (if dirty: what's uncommitted and why)
- **Active sprint:** <slug> or none
- **Last meaningful commit:** <hash> <subject>

## Your role
<ORCHESTRATOR or IMPLEMENTER — and what that means for this session>

## Mission
<2-3 sentences: what you're trying to accomplish and why it matters>

## Scope
<Numbered list of scope items. Each item: what it is, rough effort, status (done/in-progress/not-started)>

## Locked decisions
<Decisions already made that the next session must not revisit. Reference D-XX from CONTEXT.md if available.>

## Open gates
<Decisions still pending that the next session needs to resolve before proceeding.>

## Dispatch sequence
<If orchestrating: recommended wave/agent breakdown. Which items can parallelize, which are sequential.>

## Operational practices
<Branch naming, commit conventions, PR process, testing expectations — anything non-obvious about how this repo works.>

## Pickup checklist
1. Read this handoff
2. <specific first action>
3. <specific second action>
...

## Not your problem
<Explicit scope boundaries: what's out of scope and should not be touched.>

## Suggested skills
<Skills the next session should invoke, e.g. /grill, /jira:plan, /spawn>
```

## Adaptation

Scale sections to their relevance. A simple handoff (one task, no orchestration) might skip Dispatch sequence and Locked decisions entirely. A complex handoff (multi-wave sprint, multiple agents) needs all sections. Don't pad short handoffs with ceremony.

## Hard rules

- **Never auto-push or auto-merge.** The handoff is a local artifact.
- **One commit** if committing: `chore: write session handoff`
- **Don't modify any sprint state.** The handoff describes state; it doesn't change it.
- **Sensitive information:** redact, don't omit. Note what the secret does so the next session knows to look it up.
