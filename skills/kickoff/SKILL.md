---
name: kickoff
description: "Initialize a new project with PROJECT.md + ROADMAP.md in .project/, set up jira and studio, and route to the first sprint. Use when starting a new project, onboarding a new codebase, or setting up workflow infrastructure for the first time."
argument-hint: "<project description or goal>"
---

# Kickoff

One command to go from empty repo (or unfamiliar codebase) to a working project with full workflow infrastructure. Produces `.project/PROJECT.md` + `ROADMAP.md`, initializes jira and studio, and points you at the first sprint.

## Input

`$ARGUMENTS`:
- **Free text** — a description of what this project is and what you're trying to build
- **Empty** — start with adaptive questioning to understand the project

## Process

### 1. Understand the project

If the user provided a description, use it as the seed. Either way, explore:

- **Codebase scan** — `ls`, `package.json`, `Cargo.toml`, `go.mod`, `README.md`, `CLAUDE.md`, recent git history. What exists already?
- **Stack detection** — language, framework, database, deployment target
- **Existing workflow state** — `.jira/`, `.project/`, `.planning/` (legacy), `.workspacerc`

Then ask focused questions via `AskUserQuestion` (max 4 questions, bundled):

- What is this project? (one sentence)
- Who uses it and what problem does it solve?
- What are the hard constraints? (stack, timeline, compliance, team size)
- What does "done" look like for the first milestone?

Skip questions the codebase already answers.

### 2. Set up infrastructure

Run these in sequence:

**a. Studio** — if no `.workspacerc` exists, invoke `/studio:setup` semantics (create workspace, symlinks, gitignore block, hook wiring). If `.workspacerc` already exists, skip.

**b. Jira** — if no `.jira/` exists, invoke `/jira:init` semantics (bootstrap `.jira/` with STATE.md, sprints/). If `.jira/` already exists, skip.

**c. Create `.project/`** — `mkdir -p .project/`. If studio is active, this will be a symlink into the workspace.

### 3. Write PROJECT.md

Write `.project/PROJECT.md`:

```markdown
---
name: <project name>
created: <YYYY-MM-DD>
stack: <detected stack summary>
status: active
---

# <Project Name>

## Purpose
<2-3 sentences: what this project is and why it exists>

## Constraints
<bulleted list of hard constraints — technical, timeline, compliance, team>

## Success criteria
<what "done" looks like — measurable where possible>

## Stack
<language, framework, database, deployment, key dependencies>

## Team
<who's working on this — roles, not names if unknown>

## Decisions
<significant architectural or product decisions already made — reference CLAUDE.md, ADRs, or CONTEXT.md entries>
```

### 4. Write ROADMAP.md

Break the project into phases. Each phase is a milestone-level chunk that maps to one or more jira sprints.

```markdown
---
project: <project name>
created: <YYYY-MM-DD>
phases: <count>
---

# Roadmap

## Phase 1: <name>
**Goal:** <one sentence>
**Sprints:** <estimated count>
**Depends on:** —
**Status:** not-started

### Deliverables
- <deliverable 1>
- <deliverable 2>

### Success criteria
- [ ] <criterion 1>
- [ ] <criterion 2>

## Phase 2: <name>
...
```

Scale the roadmap to the project. A weekend hack gets 2-3 phases. A production app gets 5-10. Don't over-plan — the roadmap is a compass, not a GPS route.

### 5. Present and iterate

Show the user:
- PROJECT.md summary
- ROADMAP.md phase breakdown
- Infrastructure status (studio, jira)

Ask: "Does this capture the project? Should any phases merge, split, or reorder?"

Iterate until approved.

### 6. Commit and route

```bash
git add .project/PROJECT.md .project/ROADMAP.md
git commit -m "kickoff: initialize project — <project name>"
```

Then suggest the next step:
- If Phase 1 is clear enough to sprint on: "Ready for `/jira:research <phase 1 goal>`"
- If Phase 1 needs shaping first: "Ready for `/grill shape` to refine Phase 1 before sprinting"
- If the user wants to decompose Phase 1 into issues first: "Ready for `/jira:to-issues` after planning"

## Legacy migration

If `.planning/` exists (from GSD or older workflows):
1. Note its contents to the user
2. Offer to migrate relevant artifacts (PROJECT.md, ROADMAP.md equivalents) into `.project/`
3. Don't delete `.planning/` — that's a studio:migrate concern

## Hard rules

- **Never skip the user conversation.** Even if the codebase is obvious, confirm with the user. Kickoff is alignment, not automation.
- **Infrastructure is idempotent.** Re-running kickoff on an initialized project updates PROJECT.md and ROADMAP.md but doesn't re-init jira or studio.
- **Roadmap phases are NOT jira sprints.** A phase may require multiple sprints. The mapping is: phase = milestone, sprint = one research→plan→execute cycle within a phase.
- **Don't start a sprint.** Kickoff ends at the roadmap. The user decides when to start the first sprint.
- **Never push.** Commit locally only.
