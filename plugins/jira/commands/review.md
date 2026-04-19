---
description: Review the diff for the active sprint or a given branch/range. Spawns jira-reviewer; reports findings by severity. Does not fix.
allowed-tools: Bash, Read, Glob, Grep, Agent
argument-hint: [<branch> | <range> | --sprint <slug>]
---

Run a code review. By default reviews the active sprint; can also review an arbitrary branch or commit range.

## Parse the input

`$ARGUMENTS`:
- empty → review the active sprint (`cat .jira/CURRENT`)
- `--sprint <slug>` → review that sprint specifically
- `<branch>` (e.g. `feat/foo`) → review `git diff main...<branch>`
- `<range>` (e.g. `HEAD~5..HEAD`) → review that range

If you can't parse the input unambiguously, default to "active sprint" and report what you assumed.

## Steps

1. **Resolve the diff scope.** Compute `git diff <base>...<head>` (and `git log <base>..<head>` for context).

2. **Get a quick summary** before delegating: file count, +/- line count. If the diff is huge (> 2000 lines), include that in the review prompt so the reviewer paces itself.

3. **Spawn `jira-reviewer`:**
   - The diff scope (branch, range, or sprint slug)
   - All `*-PLAN.md` paths if reviewing a sprint (reviewer checks goal alignment across plans)
   - Path to CONTEXT.md if reviewing a sprint (every D-XX must have implementing code)
   - Path to EXECUTION.md if reviewing a sprint (cross-reference Nyquist results and deviations)
   - Path to VERIFICATION.md if reviewing a sprint (cross-reference goal-backward outcomes)

4. **Receive the review** (markdown output with verdict + findings by severity).

5. **If reviewing a sprint, persist the review:**
   ```bash
   echo "$REVIEW" > .jira/sprints/<slug>/REVIEW.md
   git add .jira/sprints/<slug>/REVIEW.md
   git commit -m "review(<slug>): <verdict>"
   ```
   If reviewing an arbitrary branch/range, just print to the terminal — don't commit anywhere.

6. **Report** the verdict, finding counts by severity, and the path to the saved review (if any).

## Hard rules

- **Don't fix.** Even one-liners. The reviewer reports; humans (or another `/jira:execute`) fix.
- **Don't open a PR comment.** This is a local review tool; it's intentionally separate from GitHub review.
- **Don't summarize away findings.** Pass the reviewer's output through verbatim.
