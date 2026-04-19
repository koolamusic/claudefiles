# jira

A lean, opinionated sprint workflow for Claude Code. One namespace (`jira:`), one state directory (`.jira/`), one motion: **research → plan → execute**. Plus review and retro for closing the loop, and init to bootstrap.

> **Inspired by** [GSD](https://github.com/gsd-build/get-shit-done) — `jira` is a leaner take on the same idea, distilled to the parts that proved load-bearing in daily solo work.

## Commands

| Command | Purpose |
|---|---|
| `/jira:init` | Bootstrap `.jira/` with `.gitignore`, README, `STATE.md`, and `sprints/` |
| `/jira:research [<prompt>\|--issue N]` | Spawn parallel `jira-researcher` agents; synthesize `RESEARCH.md`; update `STATE.md` |
| `/jira:plan [--push-issue]` | `jira-planner` writes CONTEXT.md + per-wave PLANs; `jira-plan-checker` audits with stall detection |
| `/jira:execute` | Wave-by-wave parallel `jira-executor`; then `jira-nyquist` (tests); then `jira-verifier` (goal-backward); opens PR |
| `/jira:review` | `jira-reviewer` reviews the current branch diff against CONTEXT and PLAN |
| `/jira:retro` | Opt-in. Generates `RETRO.md` for the active sprint or a date range; rolls workflow lessons into `STATE.md` |

## State layout

```
.jira/
├── .gitignore
├── README.md
├── STATE.md                   (project-wide: sprints, decisions log, blockers)
├── CURRENT                    (slug of active sprint)
└── sprints/
    └── YYYY-MM-DD-<slug>/
        ├── BRIEF.md           (from --issue or user prompt)
        ├── RESEARCH.md        (parallel researcher synthesis)
        ├── CONTEXT.md         (locked decisions D-XX, deferred ideas, canonical refs)
        ├── 01-PLAN.md         (one file per wave-plan, ≤3 tasks each)
        ├── 02-PLAN.md
        ├── EXECUTION.md       (commits, deviations, results — append-only)
        ├── VERIFICATION.md    (goal-backward post-execution audit)
        └── RETRO.md           (opt-in)
```

## Conventions

- **Sprints, not phases.** A sprint is one research → plan → execute cycle.
- **Multi-plan per sprint, wave-based parallelism.** The planner emits `01-PLAN.md`, `02-PLAN.md`, ... grouped into waves. Plans within a wave touch disjoint files and execute in parallel; later waves depend on earlier waves. Each plan is ≤ 3 tasks (executor quality degrades past that point in a single context).
- **CONTEXT.md is the source of truth.** Locked decisions (`D-01`, `D-02`, ...) come from `AskUserQuestion` answers during planning. Plans reference D-XX in task actions; the verifier cross-checks every D-XX has implementing code.
- **Worktree decision happens in `/jira:plan`**, not always-on. Plan declares whether the work needs isolation; execute reads that.
- **Three validation gates by default:**
  1. **Plan-checker** (pre-execute) — goal-backward audit of plans, source-coverage matrix, stall detection
  2. **Nyquist** (post-execute) — every plan's criteria has a passing test; gaps get filled
  3. **Verifier** (post-execute) — goal-backward audit of the *codebase*: does it actually deliver the goal?
- **PR is opened automatically** when execute completes green and the sprint has an associated issue.
- **`AskUserQuestion` is the discussion layer.** No dedicated discuss command — questions get asked inline where they arise.
- **Schema-push tasks** are auto-injected for Prisma / Drizzle / Payload / Supabase / TypeORM projects to prevent false-positive verification (types pass, but the live DB hasn't been pushed).

## Install

This plugin ships with the [koolamusic/claudefiles](https://github.com/koolamusic/claudefiles) marketplace. From a Claude Code session:

```
/plugin install jira@claudefiles
```

## Tradeoffs

- **No milestones, no roadmap, no project bootstrap.** A sprint is the atomic unit. If you need long-horizon planning, `jira` is the wrong tool.
- **No autonomous mode.** Each command is invoked explicitly.
- **Single-file agents.** Agents are short and don't share helpers — duplication is preferred over a shared library.
- **No SDK, no CLI.** Everything runs inside Claude Code.
- **Plan revision is capped at 2 iterations.** With stall detection — if the second pass doesn't reduce findings, the user decides.
