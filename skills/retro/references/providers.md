# Data Providers

Providers are independent and composable. Enable as many as apply. The skill merges data from all enabled providers.

## Provider: `gsd` — GSD Planning Files

**Probe:** `.planning/STATE.md` exists

**Reads:**
- `.planning/STATE.md` — Phase number, velocity, session info
- `.planning/ROADMAP.md` — Phase name, objectives, success criteria
- `.planning/REQUIREMENTS.md` — Requirement IDs mapped to phases, completion status
- `.planning/phases/<phase-dir>/*-CONTEXT.md` — Scope, boundary, decisions
- `.planning/phases/<phase-dir>/*-PLAN.md` — Task breakdowns
- `.planning/phases/<phase-dir>/*-SUMMARY.md` — Execution results, deviations, issues, decisions, metrics
- `.planning/phases/<phase-dir>/*-VALIDATION.md` — Test and verification status
- `.planning/phases/<phase-dir>/*-VERIFICATION.md` — Verification results

**Provides:** Structured phase data, requirements traceability, decision logs, deviation records, metrics.

**Phase detection:** Phase number from `STATE.md`, phase directory name from `.planning/phases/`.

**GSD auto-trigger events:** `gsd:execute-phase`, `gsd:verify-work`

## Provider: `git` — Git History

**Probe:** `.git/` directory exists

**Reads:**
- Commit log within phase date range or between tags
- Diff stats (`git diff --stat` between boundaries)
- Commit messages (for decisions, issues, context)
- Tags and branches (for phase boundary detection)
- Blame data (contributor attribution if needed)

**Provides:** Timeline, quantitative metrics (commit count, files changed, insertions/deletions), commit-message-derived decisions and issues.

**Phase detection by `phase_definition.type`:**

| Type | Boundary logic |
|------|---------------|
| `git_tag` | Commits between consecutive tags |
| `git_branch` | Commits on a merged feature/release branch |
| `date_range` | Commits within the specified time window |
| `auto` | Try tags first, fall back to merge commits on main |

**Useful git commands:**
```bash
# Commits between tags
git log v1.0..v2.0 --oneline --no-merges

# Diff stats between tags
git diff --stat v1.0..v2.0

# Commits in date range
git log --after="2026-03-01" --before="2026-03-15" --oneline

# Files changed
git diff --name-only v1.0..v2.0

# Contributors
git shortlog -sn v1.0..v2.0
```

## Provider: `github` — GitHub API

**Probe:** `gh auth status` succeeds AND repo has a remote origin

**Reads:**
- Pull requests merged during the phase (titles, descriptions, review comments, labels)
- Issues closed during the phase
- Milestone data if `phase_definition.type` is `"github_milestone"`
- CI/CD check results on phase commits
- Review comments and discussions

**Provides:** PR-derived context, issue linkage, review feedback, CI status, collaboration data.

**Useful gh commands:**
```bash
# PRs merged in date range
gh pr list --state merged --search "merged:2026-03-01..2026-03-15" --json number,title,body,labels,mergedAt

# Issues closed in date range
gh issue list --state closed --search "closed:2026-03-01..2026-03-15" --json number,title,body,labels

# Milestone issues
gh issue list --milestone "v2.0" --state all --json number,title,state

# PR reviews
gh pr view <number> --json reviews,comments

# CI checks on a commit
gh run list --commit <sha> --json conclusion,name,status
```

**GitHub auto-trigger events:** `github:milestone-close`

## Provider: `manual` — User Input

**Always available.** Cannot be disabled.

For any section that other providers cannot populate, ask the user directly. Use these prompts:

| Gap | Prompt |
|-----|--------|
| Objective unknown | "What was the objective of this phase?" |
| No success criteria | "What were the success criteria?" |
| No unexpected findings | "What surprised you during this phase?" |
| No issues surfaced | "What didn't go well?" |
| No forward risks | "What risks should the next phase watch for?" |
| Stakeholder context | "Anything the stakeholder report should highlight?" |
| No edge cases surfaced | "Were there any non-obvious scenarios or boundary conditions you encountered?" |
| No decisions logged | "What key decisions did you make during this phase, and what alternatives did you consider?" |
| Phase boundary | "What work does this phase cover? (date range, commits, description)" |

**Behavior:** Ask only for gaps. If GSD and git already cover objectives and metrics, don't re-ask those. Focus manual questions on subjective context: surprises, learnings, team morale, process friction, stakeholder concerns.

## Provider Precedence

When multiple providers supply data for the same section, merge with this priority:

1. **GSD** — Most structured, highest fidelity
2. **GitHub** — PR descriptions and issues add collaboration context
3. **Git** — Quantitative baseline
4. **Manual** — Fills remaining gaps, adds subjective context

**Never discard data from a lower-priority provider.** Merge it in. A git-derived metric and a GSD-derived metric for the same measurement should be cross-referenced, not dropped.

**Contradiction flagging:** When data from different providers conflicts (e.g., GSD reports requirements completed but git shows reverts of that work, or GSD metrics don't match git stats), the retrospective must explicitly flag the contradiction in the Findings section under Unexpected. Do not silently present both data points in different sections without reconciliation. State what each provider reports, identify the discrepancy, and note which is more reliable for this specific case.
