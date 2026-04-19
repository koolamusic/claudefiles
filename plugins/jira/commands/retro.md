---
description: Generate a retrospective for the active sprint, a specific sprint, or a date range. Opt-in — never auto-fires.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: [--sprint <slug> | --since <YYYY-MM-DD>]
---

Capture lessons from completed work. Two modes:

- **Per-sprint** (default, or `--sprint <slug>`) — one RETRO.md inside the sprint dir
- **Rollup** (`--since <date>`) — synthesize across all sprints since a date into `.jira/retros/<date>.md`

## Per-sprint mode

1. **Resolve the sprint slug:** `--sprint <slug>` or `cat .jira/CURRENT`. Stop if missing.

2. **Read** BRIEF.md, CONTEXT.md, all `*-PLAN.md` files, EXECUTION.md, VERIFICATION.md, and REVIEW.md (if any exist).

3. **Use `AskUserQuestion`** to elicit the human's view. Five tight questions, single message:
   - Outcome: shipped, partial, abandoned, other?
   - What worked best?
   - What slowed you down?
   - Biggest surprise?
   - Anything to change about the workflow itself?

   Treat the answers as raw input — do not paraphrase them.

4. **Write RETRO.md** at `.jira/sprints/<slug>/RETRO.md` using the template at `${CLAUDE_PLUGIN_ROOT}/templates/sprint/RETRO.md`. Combine:
   - **Workflow signal from disk** (commits made, deviations from EXECUTION.md, Nyquist gaps, review findings)
   - **Human signal from AskUserQuestion** (verbatim, attributed)

5. **Surface follow-ups.** If the user named concrete actions, list them as a checklist at the bottom. Don't create new sprints — that's the user's call.

6. **Update STATE.md.** Append any "Lessons for the workflow itself" to the `## Notes` section (these accumulate across sprints).

7. **Commit:**
   ```bash
   git add .jira/sprints/<slug>/RETRO.md .jira/STATE.md
   git commit -m "retro(<slug>): <one-line outcome>"
   ```

## Rollup mode (`--since YYYY-MM-DD`)

1. **Find sprints** with directory dates ≥ `<since>`: `ls .jira/sprints/ | awk -F- '{print $1"-"$2"-"$3" "$0}' | sort | awk -v d="<since>" '$1>=d {print $2}'`.

2. **Read each sprint's BRIEF, PLAN, EXECUTION, RETRO** (if RETRO exists; otherwise skip per-sprint retro and rely on plan/execution signal).

3. **Use `AskUserQuestion`** with three rollup questions:
   - Across these sprints, what pattern keeps coming up — good or bad?
   - Which sprint had the biggest learning?
   - One change you'd commit to for the next batch?

4. **Write `.jira/retros/<since>-rollup.md`**:
   - Sprint summary table (slug, goal, outcome)
   - Cross-cutting themes (3-5)
   - Follow-up actions
   - Verbatim human answers

5. **Commit:**
   ```bash
   git add .jira/retros/<since>-rollup.md
   git commit -m "retro: rollup since <since>"
   ```

## Report

Per-sprint: path to RETRO.md, count of follow-ups.
Rollup: path to rollup file, count of sprints surveyed.

## Hard rules

- **Opt-in only.** `/jira:execute` does not auto-trigger retro.
- **Verbatim human answers.** Don't smooth or paraphrase. The whole point is the user's voice.
- **Don't generate follow-up sprints.** List actions; the user starts sprints.
- **Workflow lessons are valuable.** If the user named one, surface it prominently — these accumulate into improvements to the workflow itself.
