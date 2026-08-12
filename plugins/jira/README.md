# jira

A lean, opinionated sprint workflow for Claude Code. One namespace (`jira:`), one state directory (`.jira/`), one motion: **research → plan → execute**. Plus review and retro for closing the loop, init to bootstrap, and `comment` for stakeholder-readable GitHub comments.

> **Inspired by** [GSD](https://github.com/gsd-build/get-shit-done) — `jira` is a leaner take on the same idea, distilled to the parts that proved load-bearing in daily solo work.

## Commands

| Command | Purpose |
|---|---|
| `/jira:init` | Bootstrap `.jira/` with `.gitignore`, README, `STATE.md`, and `sprints/` |
| `/jira:research [<prompt>\|--issue N]` | Spawn parallel `jira-researcher` agents; synthesize `RESEARCH.md`; update `STATE.md` |
| `/jira:plan [--push-issue]` | `jira-planner` writes CONTEXT.md + per-wave PLANs; `jira-plan-checker` audits with stall detection |
| `/jira:execute` | Wave-by-wave parallel `jira-executor`; then `jira-nyquist` (tests); then `jira-verifier` (goal-backward); opens PR |
| `/jira:issue <research\|spec\|wave> --domain <d> [--push]` | Draft a GitHub issue from the active sprint's artifacts, following `templates/issue/GUIDE.md`. Domain-aware evidence layer (backend / library / frontend / integration / infra). Push is opt-in. |
| `/jira:uat <design\|write\|run> [--plan N]` | UAT lifecycle: design test plans from acceptance criteria, write executable scripts, run and triage results with remediation file generation |
| `/jira:advisor <triage\|plan>` | Advisory gate: spawns `jira-advisor` for independent second opinion on triage recommendations or plan quality before committing |
| `/jira:triage [--plan N] [--dry-run]` | Triage sprint plans into independently-grabbable GitHub issues using vertical slices (tracer bullets). AFK/HITL classification. |
| `/jira:review` | `jira-reviewer` reviews the current branch diff against CONTEXT and PLAN |
| `/jira:retro` | Opt-in. Generates `RETRO.md` for the active sprint or a date range; rolls workflow lessons into `STATE.md` |
| `/jira:paper <description>` | Write an evidence-disciplined engineering paper (innovation/discovery/finding) from a freeform description. `jira-paper-reviewer` adversarially reviews before publish. Not sprint-scoped. |
| `/jira:comment` | Draft (default) or post a GitHub issue/PR comment in stakeholder-readable voice, with GitHub autolinks and commit-pinned code permalinks. See [`templates/comment/GUIDE.md`](templates/comment/GUIDE.md). |

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
        ├── features/          (acceptance predicates — *.feature, @req:<ID> tagged)
        ├── 01-PLAN.md         (one file per wave-plan, ≤3 tasks each; claims predicates via effects:)
        ├── 02-PLAN.md
        ├── EXECUTION.md       (commits, deviations, results — append-only)
        ├── VERIFICATION.md    (goal-backward post-execution audit)
        └── RETRO.md           (opt-in)
```

## Conventions

- **Sprints, not phases.** A sprint is one research → plan → execute cycle.
- **Multi-plan per sprint, wave-based parallelism.** The planner emits `01-PLAN.md`, `02-PLAN.md`, ... grouped into waves. Plans within a wave touch disjoint files and execute in parallel; later waves depend on earlier waves. Each plan is ≤ 3 tasks (executor quality degrades past that point in a single context).
- **CONTEXT.md is the source of truth.** Locked decisions (`D-01`, `D-02`, ...) come from `AskUserQuestion` answers during planning. Plans reference D-XX in task actions; the verifier cross-checks every D-XX has implementing code.
- **features/ is the goal set.** Every sprint declares its acceptance predicates as Gherkin scenarios in `features/*.feature`, each tagged `@req:<ID>` (domain prefix + sequential, e.g. `TOK-01`). Plans claim predicates via `effects:` frontmatter; the plan-checker blocks orphan predicates (declared, unclaimed) and phantom effects (claimed, undeclared). Feature files are lowercase — the contract; UPPERCASE.md files are working papers. Frozen at execution time.
- **Worktree decision happens in `/jira:plan`**, not always-on. Plan declares whether the work needs isolation; execute reads that.
- **Three validation gates by default:**
  1. **Plan-checker** (pre-execute) — goal-backward audit of plans, source-coverage matrix, stall detection
  2. **Nyquist** (post-execute) — every plan's criteria has a passing test; gaps get filled
  3. **Verifier** (post-execute) — goal-backward audit of the *codebase*: does it actually deliver the goal?
- **PR is opened automatically** when execute completes green and the sprint has an associated issue.
- **`AskUserQuestion` is the discussion layer.** No dedicated discuss command — questions get asked inline where they arise.
- **Schema-push tasks** are auto-injected for Prisma / Drizzle / Payload / Supabase / TypeORM projects to prevent false-positive verification (types pass, but the live DB hasn't been pushed).
- **Issue writing has a guide.** `/jira:issue` follows [`templates/issue/GUIDE.md`](templates/issue/GUIDE.md) — evidence-grounded principles distilled from three real conventions (stellar/wallet-backend H-series for backend research, vercel-labs/json-render contributor bugs for libraries, stellar/freighter-mobile for visual/integration). Domain-aware: the shape stays the same; the evidence layer changes per domain.
- **Research follows a structured synthesis pattern** inspired by [GSD](https://github.com/gsd-build/get-shit-done). Every `RESEARCH.md` carries tiered sources (HIGH/MEDIUM/LOW), Common Pitfalls with warning signs, Don't Hand-Roll calls, an Architectural Responsibility Map for multi-tier work, and a Valid-until date that acknowledges research decay. See [`templates/sprint/RESEARCH.md`](templates/sprint/RESEARCH.md). Wave-style phase numbering from GSD is intentionally not adopted — jira keeps its single-level `NN-PLAN.md` with `wave:` frontmatter.
- **Papers are not sprint-scoped.** `/jira:paper` writes evidence-disciplined engineering papers (innovation/discovery/finding) from a freeform description, not from `.jira/` state — it doesn't read or update `STATE.md`. Output is a single-file HTML per [`templates/paper/PAPER.html`](templates/paper/PAPER.html), reviewed by `jira-paper-reviewer` before publish, cataloged via [`templates/paper/index-entry.html`](templates/paper/index-entry.html) into an `artifacts/index.html` (resolved from the studio workspace root if `.jira` is studio-managed, else the repo root). The evidence discipline is internal (evidence inventory, claim-strength classification, stop conditions) — the page itself stays lean, matching the existing paper corpus rather than a full academic structure.

## The model

The sprint workflow is classical planning with an untrusted executor. A Gherkin scenario is one predicate — `Given` precondition, `When` operator, `Then` postcondition — the same triple as a [STRIPS](https://en.wikipedia.org/wiki/Stanford_Research_Institute_Problem_Solver) operator and a [Hoare logic](https://en.wikipedia.org/wiki/Hoare_logic) triple `{P} C {Q}`, written in [BDD](https://en.wikipedia.org/wiki/Behavior-driven_development) syntax. Sprint decomposition into waves of parallel-safe plans is [HTN](https://en.wikipedia.org/wiki/Hierarchical_task_network)-style ordered task decomposition. The predicate spine threads one goal set through three sensors: declared once in `features/` at plan time, claimed by plans (`effects:`), then sensed by nyquist (machine tests, at execute), `/jira:flow` (human steps), and warden (deterministic acceptance, post-sprint). Gates are hard at plan (cheapest fix point) and soft at verify — the empirical verdict belongs to the sensor that runs last.

## Install

This plugin ships with the [koolamusic/claudefiles](https://github.com/koolamusic/claudefiles) marketplace. From a Claude Code session:

```
/plugin install jira@claudefiles
```

## Tradeoffs

- **No milestones, no roadmap, no project bootstrap.** A sprint is the atomic unit. For long-horizon planning, use `/kickoff` to create `.project/PROJECT.md` + `ROADMAP.md` — `jira:research` reads these for context but doesn't manage them.
- **No autonomous mode.** Each command is invoked explicitly.
- **Single-file agents.** Agents are short and don't share helpers — duplication is preferred over a shared library.
- **No SDK, no CLI.** Everything runs inside Claude Code.
- **Plan revision is capped at 2 iterations.** With stall detection — if the second pass doesn't reduce findings, the user decides.
