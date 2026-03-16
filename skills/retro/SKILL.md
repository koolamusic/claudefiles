---
name: retro
description: "Use when a user completes a phase, sprint, milestone, or meaningful unit of work and needs a retrospective. Also triggers on `/retro` command. Generates honest, structured retrospectives from available project data (GSD planning files, git history, GitHub PRs/issues, user input). Adapts to any project — GSD-managed, plain git repos, GitHub-heavy workflows, or unstructured projects. Produces phase retrospectives, cumulative summaries, and stakeholder reports."
---

# Retrospective Skill

Generate honest, structured retrospectives for any Claude Code project. Retrospectives are the primary communication channel between engineering execution and product/stakeholder visibility.

## Core Principles

1. **Adapt to the project** — A 3-commit side project and a 50-phase enterprise migration both get useful retrospectives.
2. **Honest by default** — Surface deviations, bugs, wrong assumptions, and scope surprises prominently. Never omit negative findings.
3. **Composable providers** — Read from GSD, git, GitHub, and the user. Never write to `.planning/` or modify git history.
4. **Idempotent** — Running `/retro 1` twice overwrites the previous output. No duplicates.
5. **Manual fills the gaps** — For anything automation can't derive, ask the user.

## Commands

| Command | Description |
|---------|-------------|
| `/retro` | Retrospective for the most recently completed phase |
| `/retro <N>` | Retrospective for phase N |
| `/retro config` | Show current config and allow edits |
| `/retro status` | Show which phases have retros, which are pending, gaps |
| `/retro init` | Initialize retrospective infrastructure |

## Execution Flow

### 1. Load or Initialize Config

Read `.claude/retrospective.config.json`. If missing, run first-run initialization (see references/config.md for schema and first-run behavior).

### 2. Identify the Phase

- If phase number/name provided (e.g., `/retro 3`), use it.
- Otherwise, determine most recently completed phase from enabled providers:
  - **GSD**: read `.planning/STATE.md` for current phase
  - **Git**: find latest tag or merged branch
  - **GitHub**: find most recently closed milestone via `gh`
  - **Manual**: ask the user

### 3. Gather Phase Data

Query all enabled providers. For provider details, probe logic, and precedence rules, see references/providers.md.

Collect across providers:
- Objective, scope, success criteria
- What happened (summaries, commits, PRs)
- Decisions made (decision logs, PR descriptions, commit messages)
- Issues and deviations (reverts, fixups, issue comments)
- Quantitative metrics (git stats, PR/issue counts)
- Artifacts produced (file lists, diff stats)

**Provider precedence** (merge, never discard): GSD → GitHub → Git → Manual

### 4. Populate the Template

Use the project's template from config, or the built-in default at `_templates/PHASE-RETRO-TEMPLATE.md`. Fill all 10 sections:

| # | Section | Focus |
|---|---------|-------|
| 1 | Phase Context | Objective, scope in/out, entry conditions, success criteria table |
| 2 | Findings | Expected vs unexpected discoveries. **Prioritize unexpected.** |
| 3 | Observations | Patterns, anomalies, technical notes for future phases |
| 4 | Edge Cases | Non-obvious scenarios, how handled, impact |
| 5 | Decisions Made | Options considered, choice, rationale — audit trail |
| 6 | Risks & Issues | Issues (severity, resolution, time impact). Forward-looking risks. |
| 7 | Metrics & Progress | Planned vs actual. Requirement completion with evidence. |
| 8 | Learnings | What worked, what didn't, what we'd do differently. **Be honest.** |
| 9 | Artifacts | Table of outputs with filenames and descriptions |
| 10 | Stakeholder Highlights | Executive summary, key numbers, callouts, confidence scores |

**Tone:** Surface the bad and the ugly prominently. Sugarcoating defeats the purpose.

### 5. Completeness Check

Before writing, self-audit the retrospective. For each of the 10 sections:

| Check | Pass Condition |
|-------|----------------|
| Section present | Heading exists with content below it |
| Tables populated | Every table has at least 1 data row (not just headers) |
| No placeholder text | No `{{variables}}`, "TBD", "N/A" for entire sections |
| Manual questions asked | If a section is empty after provider data, the user was asked |
| Honesty audit | Sections 2, 6, 7, 8 must not lead with positives if negatives exist. Any language that reframes a negative outcome as positive, neutral, or as a growth opportunity is prohibited. State what failed, why, and what it cost. Banned phrases include but are not limited to: "challenges", "despite difficulties", "evolved the approach", "learning opportunity", "room for improvement", "adjusted scope/timeline", "partially achieved/met", "minor setback", "incremental progress", "opportunity for improvement", "required additional iteration", "scope refinement". |
| Confidence scores | Section 10 has Completeness, Quality, Risk Exposure scores 1-5. Use this rubric: **5** = all requirements met, no significant issues. **4** = all requirements met, minor issues resolved. **3** = most requirements met, some issues outstanding. **2** = significant requirements unmet or major issues. **1** = critical failures, phase objectives not achieved. Scores must reflect reality — do not inflate. |

**If any section is empty:** Go back to Step 3 and ask the user via manual provider. Do not write a retrospective with blank sections.

**Manual question minimums by data richness:**
- If GSD or GitHub provide structured data: minimum **3** manual questions.
- If only git and manual are active: minimum **5** manual questions (git provides metrics but not subjective context).
- If only manual is active: minimum **7** manual questions (you are the sole data source besides the user).

Go back and ask about surprises, failures, forward risks, edge cases, and decisions at minimum.

### 6. Write the Retrospective

Save to `<retrospective_dir>/phase-<N>-<slug>.md` (default: `.retrospective/`). Overwrite if exists.

**Slug derivation:** Phase name lowercased, spaces replaced with hyphens, non-alphanumeric characters (except hyphens) removed, truncated to 50 characters. If no phase name exists, use phase number only: `phase-<N>.md`.

### 7. Update Cumulative Summary

If `summary_tracker.auto_update` is true, update `<retrospective_dir>/SUMMARY.md`:
- Phase column in project-level metrics table
- Phase completion status (status, confidence, key outcome)
- Cross-phase learnings (recurring themes, compounding risks)
- Cumulative risk register
- Project-level decisions

If `SUMMARY.md` doesn't exist, create from built-in default at `_templates/SUMMARY-TEMPLATE.md`.

### 8. Generate Stakeholder Report

If `stakeholder_report.auto_generate` is true, generate `<retrospective_dir>/phase-<N>-<slug>-stakeholder.md` from `_templates/STAKEHOLDER-REPORT-TEMPLATE.md`:
- Plain language, no jargon
- Lead with outcomes and numbers
- Risks and blockers up front
- Next phase preview with readiness assessment

## Hook Enforcement

The skill ships with `hooks/retro-trigger.sh` — a real Claude Code PostToolUse hook, not just instructions.

### What It Detects

| Trigger | Tool Watched | Signal |
|---------|-------------|--------|
| GSD phase completion | `Edit`/`Write` on `.planning/STATE.md` | Status contains "complete" |
| Git tag creation | `Bash` running `git tag <name>` | Tag command pattern match |

### Behavior by Mode

- **`auto`**: Prints `[retro] Phase N complete. Auto-generating retrospective...` to stderr (exit 2). The agent sees this as a hook message and should run `/retro`.
- **`prompt`**: Prints the prompt message and writes `pending_retro` to config. User decides when to run `/retro`.
- **`manual`**: Hook exits 0 silently. No-op.

### Registration

The hook must be registered in the project's `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/retro-trigger.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/retro-reminder.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

On `/retro init`, register both hooks automatically if the project's `.claude/settings.json` doesn't already have them. **Merge into existing hook arrays — do not overwrite existing hooks for the same trigger.**

**Two hooks, two jobs:**
- `retro-trigger.sh` (PostToolUse) — detects phase completion in real time
- `retro-reminder.sh` (SessionStart) — reminds about deferred retros on session start

See references/config.md for `pending_retro` schema.

## Reference Files

- **references/config.md** — Full config schema, field reference, first-run initialization logic
- **references/providers.md** — Data provider details, probe logic, what each reads, precedence rules
- **_templates/PHASE-RETRO-TEMPLATE.md** — Default phase retrospective template
- **_templates/STAKEHOLDER-REPORT-TEMPLATE.md** — Default stakeholder report template
- **_templates/SUMMARY-TEMPLATE.md** — Default cumulative summary template
