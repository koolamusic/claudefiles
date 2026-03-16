# Retrospective Config Reference

## Config Location

`.claude/retrospective.config.json` in the project root. Single source of truth for how retrospectives behave.

## Full Schema

```json
{
  "enabled": true,
  "mode": "prompt",
  "retrospective_dir": ".retrospective",
  "templates": {
    "phase_retro": "_templates/PHASE-RETRO-TEMPLATE.md",
    "stakeholder_report": "_templates/STAKEHOLDER-REPORT-TEMPLATE.md"
  },
  "data_sources": {
    "providers": {
      "gsd": { "enabled": false },
      "git": { "enabled": true },
      "github": { "enabled": false },
      "manual": { "enabled": true }
    }
  },
  "phase_definition": {
    "type": "auto",
    "custom_label": null
  },
  "auto_trigger_after": [],
  "sections": {
    "context": true,
    "findings": true,
    "observations": true,
    "edge_cases": true,
    "decisions": true,
    "risks": true,
    "metrics": true,
    "learnings": true,
    "artifacts": true,
    "stakeholder_highlights": true
  },
  "stakeholder_report": {
    "auto_generate": true,
    "distribution_list": []
  },
  "summary_tracker": {
    "auto_update": true,
    "file": "SUMMARY.md"
  },
  "hooks": {
    "post_phase_complete": {
      "enabled": true,
      "behavior": "prompt"
    }
  },
  "pending_retro": null
}
```

## Field Reference

### `mode`

Controls when retrospectives run:

| Value | Behavior |
|-------|----------|
| `"prompt"` | After phase completes, ask: *"Phase N is complete. Write the retrospective now?"* If deferred, store in `pending_retro` and remind at next session start. |
| `"auto"` | Generate immediately on phase completion detection. No user interaction. |
| `"manual"` | Only run when the user explicitly invokes `/retro`. |

### `data_sources.providers`

Each provider is `{ "enabled": true/false }`. The skill probes for available providers on first run and sets initial values. The user can override at any time.

- `gsd` — GSD planning files
- `git` — Git history (almost always available)
- `github` — GitHub API via `gh` CLI
- `manual` — User input (always enabled, cannot be disabled)

### `phase_definition.type`

How the project defines "a phase":

| Value | Source |
|-------|--------|
| `"auto"` | Infer from available providers |
| `"gsd_phase"` | GSD phase directory in `.planning/phases/` |
| `"git_tag"` | Tagged release or version in git |
| `"git_branch"` | Merged feature/release branch |
| `"github_milestone"` | GitHub milestone |
| `"date_range"` | Time window (sprint-style) |
| `"manual"` | User defines each phase boundary explicitly |

### `phase_definition.custom_label`

Optional rename. If a team calls phases "sprints", "iterations", or "releases", this label replaces "Phase" throughout all output.

### `auto_trigger_after`

List of events that trigger automatic retrospective generation. Examples:
- `"gsd:execute-phase"`, `"gsd:verify-work"` — GSD lifecycle events
- `"git:tag"` — New git tag created
- `"github:milestone-close"` — GitHub milestone closed

Empty array means no auto-triggering.

### `pending_retro`

When mode is `"prompt"` and the user defers, stores pending state:

```json
{
  "phase": 1,
  "phase_name": "Sitemap Audit",
  "deferred_at": "2026-03-16T10:00:00Z"
}
```

On next conversation start, if non-null, remind the user.

### `sections`

Toggle individual sections on/off. All default to `true`. Set to `false` to skip a section entirely.

### `stakeholder_report`

- `auto_generate` — If `true`, generate a stakeholder report alongside every retrospective.
- `distribution_list` — Informational. List of stakeholders who receive the report.

### `summary_tracker`

- `auto_update` — If `true`, update the cumulative `SUMMARY.md` after each retrospective.
- `file` — Filename for the summary tracker (relative to `retrospective_dir`).

## First-Run Initialization

If `.claude/retrospective.config.json` doesn't exist when the skill is invoked:

### Step 1: Probe the Project

| Check | Provider | How |
|-------|----------|-----|
| `.planning/STATE.md` exists? | `gsd` | File existence check |
| `.git/` exists? | `git` | File existence check |
| `gh auth status` succeeds with remote? | `github` | Run command, check exit code |
| Always | `manual` | Always enabled |

### Step 2: Check Existing Infrastructure

- Does a `.retrospective/` directory with existing retros exist? → Point config to it.
- If not, create the directory structure and write default templates.

### Step 3: Determine Phase Definition

Priority order:
1. GSD available → `"gsd_phase"`
2. Git tags present → `"git_tag"`
3. GitHub milestones exist → `"github_milestone"`
4. Nothing → `"manual"`

### Step 4: Ask the User

Two questions:
1. *"How should retrospectives trigger? Options: `auto` (generate after each phase), `prompt` (ask you first), or `manual` (only when you run /retro)."*
2. *"Does your team call these something other than 'phases'? (e.g., sprints, iterations, releases)"*

### Step 5: Write Config

Write `.claude/retrospective.config.json` with detected values and user preferences.

### Step 6: Confirm and Proceed

Display the config summary. If a completed phase exists, proceed to generate the first retrospective.
