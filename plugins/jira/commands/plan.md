---
description: Plan the active sprint. jira-planner produces 01-PLAN.md, 02-PLAN.md per wave plus CONTEXT.md; jira-plan-checker audits all plans. Stall detection on revision. Optionally pushes a GitHub issue.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
argument-hint: [--push-issue]
---

Convert the active sprint's RESEARCH.md into one or more executable PLAN files (one per wave-plan), plus CONTEXT.md.

## Parse the input

`$ARGUMENTS` may include `--push-issue`. No other flags.

## Steps

1. **Locate the active sprint:** `slug=$(cat .jira/CURRENT)`. If empty or missing, stop — there's no active sprint to plan.

2. **Verify inputs exist:**
   - `.jira/sprints/<slug>/BRIEF.md`
   - `.jira/sprints/<slug>/RESEARCH.md`

   If either missing, stop and tell the user to run `/jira:research` first.

3. **First pass — spawn `jira-planner`:**
   - Sprint slug
   - Brief path, research path
   - Context path: `.jira/sprints/<slug>/CONTEXT.md` (may not exist; planner creates it)
   - Plan output dir: `.jira/sprints/<slug>/`
   - References: PLAN template + CONTEXT template

   The planner may use `AskUserQuestion` (≤ 4 questions, bundled) for load-bearing ambiguity. Answers become CONTEXT.md decisions (D-XX).

4. **Handle planner return.** One of:
   - `## PLANNING COMPLETE` — proceed to step 5.
   - `## ⚠ Source Audit: Unplanned Items Found` — surface the gap list via `AskUserQuestion`. Three options: A) re-spawn planner with instruction to add covering plans, B) split sprint, C) defer items to CONTEXT.md `## Deferred ideas`. Then proceed.
   - `## SPRINT SPLIT RECOMMENDED` — surface the proposal via `AskUserQuestion`. If user accepts, create the sub-sprint dirs and re-route to research. If user proceeds anyway, re-spawn planner with "force-fit" instruction.

5. **Audit pass — spawn `jira-plan-checker`** with all `*-PLAN.md` paths + brief + research + context. Returns a YAML block with `verdict`, `issue_count`, `findings`, `required_revisions`.

6. **Stall-aware revision loop (max 2 iterations):**

   - Track `prev_issue_count` (initialized to ∞ before the first audit).
   - If `verdict: REVISE`:
     - If `issue_count >= prev_issue_count`: **stalled** — surface findings via `AskUserQuestion` with options: A) proceed-with-issues, B) re-spawn planner with explicit guidance, C) abandon. Exit if A or C.
     - Otherwise: re-spawn `jira-planner` with `required_revisions` appended. Re-audit. Set `prev_issue_count = issue_count`.
     - **At most 2 iterations.** After the second audit if still REVISE: surface findings, ask the user to accept-as-is / manually-edit / abandon.

7. **If `--push-issue` was passed and the brief has no associated issue yet:**
   ```bash
   gh issue create \
     --title "<sprint goal from PLAN frontmatter>" \
     --body "$(cat <<'EOF'
   <plan summary: goal, plan count by wave, CONTEXT.md decision count>

   See \`.jira/sprints/<slug>/\` for the full plan set.
   EOF
   )"
   ```
   Capture the new issue number, write it back into every PLAN frontmatter (`issue: <N>`) and BRIEF.md (`Issue: <url>`).

8. **Update STATE.md.** Update the active sprint's row to status `planned`. Update `last_activity`. Append decisions log entries for each `D-XX` written into CONTEXT.md.

9. **Commit:**
   ```bash
   git add .jira/sprints/<slug>/CONTEXT.md .jira/sprints/<slug>/*-PLAN.md .jira/sprints/<slug>/BRIEF.md .jira/STATE.md
   git commit -m "plan(<slug>): <one-sentence goal from PLAN.md>"
   ```

10. **Report:**
    - Goal (from any PLAN frontmatter — they all share it)
    - Plan count + wave breakdown ("3 plans across 2 waves: [I,II] then [III]")
    - CONTEXT decisions: locked count, deferred count, claude's-discretion count
    - Schema push required (yes / no — from planner return)
    - Worktree decision
    - Issue URL (if pushed or pre-existing)
    - Next step: `/jira:execute`

## Hard rules

- **Run the checker, always.** Even on simple plans.
- **Stall detection is mandatory.** A revision that doesn't reduce findings is a signal to involve the human, not to keep iterating.
- **Max 2 revision iterations.**
- **Source-audit gaps are not silently dropped.** User decides per item.
- **Don't execute.** Stop at the commit. `/jira:execute` is the next motion.
- **Issue push is opt-in.** Only when `--push-issue` is passed.
- **STATE.md must be updated.** Sprint status transition (`researching` → `planned`) is load-bearing for resume.
