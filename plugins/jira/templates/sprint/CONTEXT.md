---
sprint: {{sprint_slug}}
created: {{date}}
status: ready_for_planning
---

# Context: {{sprint_slug}}

User's locked decisions for this sprint. Sourced from `AskUserQuestion` answers during `/jira:research` and `/jira:plan`. Once written here, decisions are NON-NEGOTIABLE for downstream agents.

## Phase boundary

What this sprint delivers (and what it doesn't). Pulled from the brief.

## Decisions

Each decision gets an ID (`D-01`, `D-02`, ...). Plans reference these IDs in task actions for traceability.

- **D-01:** {{decision}}
- **D-02:** {{decision}}

## Claude's discretion

Areas the user explicitly delegated. Planner uses judgment; documents the choice in task actions.

- {{area}}

## Deferred ideas

Things the user wants but explicitly NOT in this sprint. Plans MUST NOT implement these.

- {{idea}} → next sprint / future / never

## Canonical references

External specs, ADRs, prior PRs the planner and executor must read.

- `path/to/spec.md` — what it decides
