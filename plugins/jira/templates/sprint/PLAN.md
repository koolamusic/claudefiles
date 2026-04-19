---
sprint: {{sprint_slug}}
plan: {{NN}}                # 01, 02, 03 — one file per parallel-safe group
wave: {{N}}                 # tasks within the same wave can run in parallel; later waves depend on earlier
goal: {{one_sentence_goal}} # inherits from sprint; appears in every plan for traceability
worktree: false             # sprint-level decision; same value across all plans of one sprint
branch: jira/{{sprint_slug}}
issue: {{issue_number_or_none}}
depends_on: []              # plan numbers from earlier waves this one needs
parallel_with: []           # other plan numbers in the SAME wave
files_modified:             # exhaustive list — used for parallel-safety check by orchestrator
  - path/to/file.ts
covers:                     # source items this plan addresses (D-XX, REQ-XX, RESEARCH bullets)
  - D-01
  - GOAL: <fragment>
---

# Plan {{NN}}: {{plan_title}}

**Sprint goal:** {{sprint_goal}}
**This plan delivers:** {{what_this_subset_does}}

## Tasks

Each task is atomic — one commit. Max 3 tasks per plan (quality degrades past that point in a single executor's context window).

### 1. {{task_title}}

- **Files:** `path/to/file.ts`
- **Read first:** `path/to/source-of-truth.ts` (the file being modified, plus any reference implementation)
- **Action:** Concrete instructions with actual values — config keys, function signatures, exact strings. Reference decision IDs from CONTEXT.md (e.g. "per D-03").
- **Done when:** Observable, grep-verifiable, or command-output-checkable condition. NOT "tests pass" alone.
- **Covers:** D-01, GOAL fragment

### 2. {{task_title}}

- **Files:**
- **Read first:**
- **Action:**
- **Done when:**
- **Covers:**

## Nyquist criteria for this plan

Subset of the sprint's full Nyquist set that this plan is responsible for. The plan must close these criteria before the next wave runs.

- [ ] {{criterion}}

## Risks accepted in this plan

What this plan knowingly does not handle. (Future plan, future sprint, or out of scope.)
