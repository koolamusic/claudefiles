---
description: Bootstrap .jira/ in the current repo. Idempotent. Creates .jira/{.gitignore, README.md, STATE.md, sprints/, CURRENT}.
allowed-tools: Bash, Read, Write
argument-hint: (no arguments)
---

Bootstrap a `jira` workspace in the current git repository.

## Steps

1. **Verify git repo.** Run `git rev-parse --show-toplevel`. If not a git repo, stop and tell the user to `git init` first — `jira` is built around branches, worktrees, and PRs.

2. **Move to repo root.** All paths below are relative to `git rev-parse --show-toplevel`.

3. **Check for existing `.jira/`.** If it exists with a `STATE.md` file, report it and exit — do not overwrite. (CURRENT may exist or not depending on whether a sprint is active.)

4. **Create the layout:**
   ```
   .jira/
   ├── .gitignore
   ├── README.md
   ├── STATE.md         (project-wide state)
   ├── CURRENT          (empty — populated by /jira:research)
   └── sprints/         (empty directory)
   ```

5. **Copy the gitignore template** from `${CLAUDE_PLUGIN_ROOT}/templates/gitignore` to `.jira/.gitignore`.

6. **Copy the STATE.md template** from `${CLAUDE_PLUGIN_ROOT}/templates/STATE.md` to `.jira/STATE.md`. Substitute frontmatter placeholders:
   - `{{project_name}}` → basename of the repo root
   - `{{date}}` (twice — `created` and `last_activity`) → today's date in `YYYY-MM-DD`
   - `{{none_or_slug}}` → empty string

7. **Write `.jira/README.md`** with a 12-line explanation of the convention. Keep it short:

   ```markdown
   # .jira/

   Sprint state for the [jira](https://github.com/koolamusic/claudefiles/tree/main/plugins/jira) workflow.

   - `STATE.md` — project-wide state: sprint list, decisions log, blockers
   - `CURRENT` — slug of the active sprint
   - `sprints/YYYY-MM-DD-<slug>/` — one sprint per directory:
     - `BRIEF.md` (problem statement)
     - `RESEARCH.md` (parallel researcher synthesis)
     - `CONTEXT.md` (locked decisions D-XX, deferred ideas, canonical refs)
     - `01-PLAN.md`, `02-PLAN.md`, ... (one per wave-plan, ≤3 tasks each)
     - `EXECUTION.md` (commits, deviations, results)
     - `VERIFICATION.md` (goal-backward post-execution audit)
     - `RETRO.md` (opt-in)

   All files inside sprints are committed.
   Run `/jira:research <prompt>` or `/jira:research --issue N` to start a sprint.
   ```

8. **Stage and commit** (do NOT push):
   ```bash
   git add .jira/
   git commit -m "chore: bootstrap jira workspace (.jira/)"
   ```
   If `git add` fails because `.jira/` is gitignored at a parent level, surface that and stop.

9. **Report:**
   ```
   .jira/ bootstrapped. Next: /jira:research <your-prompt> or /jira:research --issue <N>
   ```

## Hard rules

- **Idempotent.** Re-running on an initialized repo is a no-op + report, never a destructive overwrite.
- **One commit.** Don't split init into multiple commits.
- **Never run `git push`.**
