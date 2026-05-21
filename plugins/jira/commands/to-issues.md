---
description: "Break the active sprint's plans into independently-grabbable GitHub issues using vertical slices. Adapted from mattpocock's to-issues pattern. Uses caveman lite."
allowed-tools: Bash, Read, Write, Glob, Grep, AskUserQuestion
argument-hint: "[--plan N] [--dry-run]"
---

Decompose sprint plans into GitHub issues — one issue per vertical slice that cuts through all layers end-to-end.

## Parse the input

`$ARGUMENTS`:
- `--plan N` — decompose only plan N (default: all plans)
- `--dry-run` — show the breakdown without creating issues

## Locate the sprint

```bash
slug=$(cat .jira/CURRENT)
sprint_dir=".jira/sprints/${slug}"
```

Stop if no active sprint or no plans exist.

## Steps

### 1. Gather context

Read:
- All `*-PLAN.md` files (or targeted plan)
- `CONTEXT.md` — locked decisions constrain slice boundaries
- `BRIEF.md` — the original problem statement (issues reference back to it)
- `.project/PROJECT.md` if it exists — project vocabulary for issue titles
- `CLAUDE.md` — domain glossary

### 2. Explore the codebase

Before slicing, understand the layers the slices will cut through. Identify:
- Data layer (schema, migrations, models)
- API/service layer (routes, handlers, services)
- UI layer (components, pages, routes) — if applicable
- Test layer (existing test patterns, fixtures)

### 3. Draft vertical slices

Break each plan into **tracer bullet** slices. Each slice is a thin vertical cut through ALL layers, not a horizontal slice of one layer.

For each slice, determine:
- **Title** — short, uses project vocabulary
- **Type** — AFK (agent can implement) or HITL (needs human judgment)
- **Blocked by** — other slice IDs that must complete first
- **Acceptance criteria** — specific, testable, covers the full vertical
- **Wave** — which wave from the source plan this slice belongs to

Slice rules:
- Each slice delivers a narrow but COMPLETE path through every layer
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
- AFK slices should be detailed enough that a sub-agent can implement without asking questions

### 4. Present the breakdown

```
## Issue Breakdown — <slug>

Source: <plan count> plans across <wave count> waves
Slices: <total> (<AFK count> AFK, <HITL count> HITL)

| # | Title | Type | Wave | Blocked by | Criteria |
|---|---|---|---|---|---|
| 1 | ... | AFK | 1 | — | 3 |
| 2 | ... | AFK | 1 | — | 2 |
| 3 | ... | HITL | 2 | 1 | 4 |

Proceed?
```

Ask via `AskUserQuestion`:
- Does the granularity feel right?
- Are dependency relationships correct?
- Should any slices merge or split?
- Are AFK/HITL assignments correct?

Iterate until approved.

### 5. Publish issues (unless --dry-run)

For each approved slice, in dependency order (blockers first):

```bash
gh issue create \
  --title "<slice title>" \
  --label "<AFK: ready-for-agent | HITL: ready-for-human>" \
  --body "$(cat <<'EOF'
## Parent

<sprint brief issue URL, if one exists>

## What to build

<concise end-to-end description of this vertical slice>

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

<issue references to blockers, or "None — can start immediately">

## Sprint context

Sprint: `<slug>`
Plan: `<NN>-PLAN.md`
Wave: <N>
EOF
)"
```

Capture each issue URL. After all are created, write a summary to `.jira/sprints/<slug>/ISSUES.md`:

```markdown
# Issues — <slug>

| # | Issue | Title | Type | Status |
|---|---|---|---|---|
| 1 | #<N> | ... | AFK | open |
| 2 | #<N+1> | ... | AFK | open |
```

### 6. Commit

```bash
git add .jira/sprints/<slug>/ISSUES.md
git commit -m "issues(<slug>): <count> issues created"
```

### 7. Report

- Issue count (AFK vs HITL)
- Issue URLs
- Dependency chain summary
- Suggested next: `/jira:execute` for AFK issues, or assign HITL issues manually

## Hard rules

- **Vertical, not horizontal.** A slice that only touches the DB layer is not a slice — it's a task. Every slice cuts through all relevant layers.
- **Dependency order for publishing.** Blockers get created first so blocked issues can reference real issue numbers.
- **Don't close or modify parent issues.** Creating child issues doesn't change the parent.
- **AFK means truly AFK.** If a slice needs a design decision, architecture call, or manual testing that can't be scripted, it's HITL.
- **Caveman lite.** Keep issue titles and descriptions tight. No filler, no preambles, no "this issue tracks..." — state what to build and the criteria.
