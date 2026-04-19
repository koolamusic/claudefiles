---
description: Start a sprint by researching it. Spawns parallel jira-researcher agents (codebase, patterns, external) and synthesizes findings into RESEARCH.md. Updates STATE.md.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
argument-hint: "<problem statement>" OR --issue <N>
---

Begin a sprint. The first deliverable is `RESEARCH.md`. Subsequent commands are `/jira:plan` then `/jira:execute`.

## Parse the input

`$ARGUMENTS` is one of:
- A free-text problem statement, e.g. `add rate limiting to /api/login`
- `--issue <N>` — pull a GitHub issue as the sprint brief

If empty, use `AskUserQuestion` to ask what the user wants to work on. Don't proceed without a brief.

## Steps

1. **Verify `.jira/` exists.** If not, run `/jira:init` semantics yourself (or tell the user to).

2. **Build the sprint slug:** `YYYY-MM-DD-<short-kebab-from-brief>`. Slug ≤ 40 chars, lowercase, alphanumeric + hyphens. Use `date -u +%Y-%m-%d`.

3. **Create the sprint directory:** `.jira/sprints/<slug>/`. If a date+slug collision, append `-2`, `-3`, etc.

4. **Write BRIEF.md** at `.jira/sprints/<slug>/BRIEF.md`:
   - **If `--issue N`:** run `gh issue view N --json title,body,url,labels,state` and use the JSON to populate the template at `${CLAUDE_PLUGIN_ROOT}/templates/sprint/BRIEF.md`. Include the URL in the `Issue:` field.
   - **If free text:** populate the template directly. Don't expand the user's words; record them.

5. **Spawn three `jira-researcher` agents in parallel** (single message, three Agent tool calls). Each gets:
   - The sprint slug
   - The brief path
   - One focus area: `codebase`, `patterns`, `external`
   - An output path: `.jira/sprints/<slug>/research-<focus>.md`

   The agents will also pick up `.jira/sprints/<slug>/CONTEXT.md` if it exists (it doesn't, on first pass — but the convention holds for re-research).

6. **Synthesize.** When all three return, read the three `research-<focus>.md` files and write `.jira/sprints/<slug>/RESEARCH.md` using the template at `${CLAUDE_PLUGIN_ROOT}/templates/sprint/RESEARCH.md`. Don't paraphrase the per-focus files into oblivion — keep their headlines and citations. The synthesis adds the cross-cut: contradictions between focus areas, the open questions for the planner.

7. **Set CURRENT:** `echo <slug> > .jira/CURRENT`.

8. **Update STATE.md.** Append a row to the `## Sprints` table:
   ```
   | <slug> | researching | <one-line goal from brief> | — |
   ```
   Update the frontmatter `last_activity` and `active_sprint` fields.

9. **Commit:**
   ```bash
   git add .jira/sprints/<slug>/ .jira/CURRENT .jira/STATE.md
   git commit -m "research(<slug>): start sprint"
   ```

10. **Report** to the user:
    - The sprint slug
    - 3-5 bullet headline from RESEARCH.md
    - The open questions count
    - Next step: `/jira:plan`

## Hard rules

- **Three researchers, in parallel.** Single message, three Agent calls. Don't go sequential.
- **Don't write a plan.** Even if the answer feels obvious. Stop at RESEARCH.md.
- **Don't push the GH issue back yet.** That happens in `/jira:plan --push-issue` if the user asks.
- **Per-focus files stay on disk.** Don't delete `research-<focus>.md` after synthesis — they're the source.
- **Always update STATE.md.** Sprint creation must reflect in the project-wide state, otherwise resume-after-context-reset breaks.
