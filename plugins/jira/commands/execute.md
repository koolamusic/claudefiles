---
description: Execute the active sprint wave-by-wave with parallel jira-executor instances per wave. Then jira-nyquist (test gates), then jira-verifier (goal-backward), then PR. Updates STATE.md throughout.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
argument-hint: (no arguments)
---

Execute the active sprint to completion: every plan executed (parallel within wave), Nyquist criteria validated, goal-backward verification, PR opened.

## Steps

1. **Locate the active sprint:** `slug=$(cat .jira/CURRENT)`. Stop if missing.

2. **Verify plans exist:** `ls .jira/sprints/<slug>/*-PLAN.md`. Stop if zero — tell the user to run `/jira:plan`.

3. **Read frontmatter from all plans.** Build a wave map (wave and plan IDs are Roman):
   ```
   wave I: [I, II]
   wave II: [III]
   wave III: [IV, V]
   ```
   Pull `worktree`, `branch`, `issue` from any plan (they share these).

4. **Validate parallel-safety within each wave.** For each wave, confirm no two plans have overlapping `files_modified`. If overlap detected, stop and report — this is a planner bug, route back to `/jira:plan`.

5. **Update STATE.md.** Set sprint status to `executing`. Update `last_activity`.

6. **Verify clean working tree** before delegating: `git status --porcelain`. If dirty, ask via `AskUserQuestion`: stash / commit-elsewhere / abort. Don't auto-stash.

7. **Wave-by-wave execution.** For each wave in order:

   - **Spawn one `jira-executor` per plan in this wave, in parallel** (single message, N Agent calls). Each executor receives:
     - Sprint slug, its plan path, all plan paths (for parallel_with awareness), context path, execution log path, execution template.
   - **Wait for all executors in this wave to return.** Collect their statuses.
   - **If any executor returns `deviation` or `blocked`:** stop the wave loop. Surface the EXECUTION.md notes via `AskUserQuestion`: revise plan, retry from current wave, or abort. Don't auto-revise.
   - **If all executors return `complete`:** proceed to next wave.

8. **All waves done — spawn `jira-nyquist`** with sprint slug + all plan paths + execution log path + worktree path (if any). Returns `GAPS FILLED` (green), `PARTIAL` (red), `ESCALATE` (red), or `NO TEST INFRA`.

9. **If Nyquist `red`:** surface the failing/escalated criteria via `AskUserQuestion`: route back to executor (with new task), accept-as-is and proceed with caveat, or abort.

10. **If Nyquist `NO TEST INFRA`:** ask user via `AskUserQuestion` whether to proceed without test validation or pause to set up testing.

11. **If Nyquist green** (or user accepts caveat) — **spawn `jira-verifier`** with sprint slug + sprint dir + all plan paths + context path + execution path + verification output path + verification template. Returns `verdict: PASS | PARTIAL | FAIL`.

12. **If verifier `FAIL`:** the goal isn't actually delivered. Surface VERIFICATION.md findings via `AskUserQuestion`: route back to planner with the gap list, route back to executor for specific outcomes, or abort. **Do NOT open a PR on a FAIL.**

13. **If verifier `PARTIAL`:** surface findings via `AskUserQuestion`: extend sprint with follow-up plan, accept-as-is and open PR with caveat in body, or abort.

14. **If verifier `PASS`** — open the PR.

   - **Determine the worktree to PR from.** If `worktree: true`, the branch is `<branch>` from PLAN frontmatter and lives in the worktree the executor created. If `worktree: false`, the branch is the current branch (it should not be `main` — if it is, ask the user which branch to push to).
   - Push: `git push -u origin <branch>`
   - Open PR:
     ```bash
     gh pr create \
       --title "<sprint goal from any PLAN frontmatter>" \
       --body "$(cat <<'EOF'
     ## Summary
     <one-sentence goal>

     ## Sprint
     `.jira/sprints/<slug>/`

     ## Closes
     <Closes #<issue> if frontmatter has issue, else omit>

     ## Plans
     <N> plans across <W> waves.

     ## Validation
     - Nyquist: <count> criteria, all green.
     - Verifier: PASS — <count> outcomes delivered, <count> CONTEXT decisions implemented.

     ## Test plan
     <bullets from each plan's Nyquist criteria>

     🤖 Generated with [Claude Code](https://claude.com/claude-code)
     EOF
     )"
     ```
   - Capture the PR URL, append to EXECUTION.md.

15. **Final commit on sprint dir:**
    ```bash
    git add .jira/sprints/<slug>/EXECUTION.md .jira/sprints/<slug>/VERIFICATION.md .jira/STATE.md
    git commit -m "execute(<slug>): complete — <PR URL>"
    ```
    If working in a separate worktree, this commit happens there too.

16. **Update STATE.md.** Set sprint status to `done` (or `verifying` if PARTIAL was accepted with follow-up agreed). Outcome column gets the PR URL. Add any unresolved gaps to `## Blockers`. Clear `active_sprint` only if the user confirms — they may want to keep it pointed for retro.

17. **Report:**
    - Plans completed (count)
    - Nyquist results (criteria covered count)
    - Verifier verdict (PASS/PARTIAL/FAIL + outcome counts)
    - PR URL
    - Suggest `/jira:retro` if the user wants to capture lessons

## Hard rules

- **Wave-safe parallelism.** Plans within a wave run in parallel; overlapping `files_modified` is a hard stop.
- **Never `git push --force`.** Surface and ask if push is rejected.
- **Never bypass Nyquist red without user confirmation.**
- **Never bypass verifier FAIL.** Goal-backward audit is a gate, not a suggestion.
- **Never auto-merge the PR.** Open and stop.
- **Don't auto-clear CURRENT.** User keeps it pointed until they start a new sprint or explicitly close out.
- **STATE.md updates at every transition** — `executing` on start, `done` on PR open. Resume relies on this.
