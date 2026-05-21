---
description: "UAT lifecycle for the active sprint. Three modes: design (generate test plans from acceptance criteria), write (produce executable scripts), run (execute and triage results). Writes to .uat/ or .jira/sprints/<slug>/uat/."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
argument-hint: "<design|write|run> [--plan N] [--all]"
---

Manage UAT (User Acceptance Testing) for the active sprint. Each mode builds on the previous — design produces the plan, write produces the scripts, run executes and triages.

## Parse the input

`$ARGUMENTS`:
- `design` — generate test plans from CONTEXT.md + PLAN acceptance criteria
- `write` — produce executable test scripts from an existing UAT plan
- `run` — execute scripts, parse results, generate remediation files from failures
- `--plan N` — target a specific plan (e.g. `--plan 01`). Default: all plans.
- `--all` — run all UAT scripts, not just the active sprint's

If empty, default to `design` (safest starting point).

## Locate the sprint

```bash
slug=$(cat .jira/CURRENT)
sprint_dir=".jira/sprints/${slug}"
```

Stop if no active sprint. UAT without sprint context is unsupported — use a testing framework directly.

## Determine UAT directory

Check for `.workspacerc`:
- If studio-managed: resolve `.uat/` through the workspace path
- Otherwise: use `.uat/` at the project root

Create `.uat/plans/` and `.uat/remediation/` if they don't exist.

## Mode: design

Generate UAT test plans from sprint artifacts.

1. **Read sprint context:**
   - All `*-PLAN.md` files (or just `--plan N`)
   - `CONTEXT.md` (locked decisions inform test scenarios)
   - `VERIFICATION.md` if it exists (goal-backward criteria become test assertions)

2. **Detect the project stack.** Scan `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Gemfile`, etc. The stack determines:
   - Script language (bash is always the fallback)
   - Available test runners / assertion libraries
   - How to start/stop the application under test

3. **For each plan (or the targeted plan), produce a UAT plan file:**

   Path: `.uat/plans/<NN>-<slug>.md` where NN is the plan number and slug is derived from the plan's goal.

   Structure:
   ```markdown
   ---
   plan: <NN>
   sprint: <slug>
   goal: <one-line from PLAN>
   prerequisites: <what must be running/configured>
   created: <YYYY-MM-DD>
   ---

   # UAT: <goal>

   ## Prerequisites
   <what needs to be running, configured, or seeded>

   ## Scenarios

   ### 1. <scenario name>
   **Given:** <precondition>
   **When:** <action>
   **Then:** <expected outcome>
   **Verify:** <specific assertion — HTTP status, DB state, UI element, log entry>

   ### 2. <scenario name>
   ...

   ## Edge Cases
   <scenarios for boundary conditions, error paths, concurrent access>

   ## Regression Checks
   <existing behavior that must NOT break — reference specific features/routes>
   ```

4. **Present the plan** via `AskUserQuestion`: approve, request changes, or add scenarios. Iterate until approved.

5. **Commit:**
   ```bash
   git add .uat/plans/
   git commit -m "uat(<slug>): design test plans"
   ```

## Mode: write

Produce executable test scripts from UAT plans.

1. **Read UAT plans** from `.uat/plans/` (all, or `--plan N`).

2. **Generate scripts** at `.uat/scripts/<NN>-<slug>.sh` (bash) or `.uat/scripts/<NN>-<slug>.<ext>` for other stacks.

   Bash script structure:
   ```bash
   #!/usr/bin/env bash
   set -uo pipefail

   # UAT: <goal>
   # Sprint: <slug>
   # Plan: <NN>

   PASS=0; FAIL=0; SKIP=0

   pass() { ((PASS++)); echo "  PASS: $1"; }
   fail() { ((FAIL++)); echo "  FAIL: $1"; }
   skip() { ((SKIP++)); echo "  SKIP: $1"; }

   # --- Prerequisites ---
   <check prerequisites, skip all if not met>

   # --- 1. <scenario name> ---
   echo "Testing: <scenario name>"
   <test commands>
   <assertion — use pass/fail/skip>

   # --- 2. <scenario name> ---
   ...

   # --- Summary ---
   echo ""
   echo "=== UAT Results: <goal> ==="
   echo "PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP"
   echo ""

   if [ "$FAIL" -gt 0 ]; then
     echo "STATUS: FAILED"
     exit 1
   else
     echo "STATUS: PASSED"
     exit 0
   fi
   ```

3. **Make scripts executable:** `chmod +x .uat/scripts/*.sh`

4. **Commit:**
   ```bash
   git add .uat/scripts/
   git commit -m "uat(<slug>): write test scripts"
   ```

## Mode: run

Execute UAT scripts and triage results.

1. **Run scripts** from `.uat/scripts/` (all, or `--plan N`).
   ```bash
   for script in .uat/scripts/<target>; do
     echo "=== Running: $script ==="
     bash "$script" 2>&1 | tee ".uat/results/$(basename "$script" .sh).log"
   done
   ```

   Create `.uat/results/` if needed.

2. **Parse results.** For each script:
   - Extract PASS/FAIL/SKIP counts from the summary line
   - Capture the exit code
   - If FAIL > 0: generate a remediation file

3. **Generate remediation files** for failures:

   Path: `.uat/remediation/<NN>-<scenario-slug>.md`
   ```markdown
   ---
   plan: <NN>
   scenario: <scenario name>
   severity: <BLOCKER|HIGH|MEDIUM>
   sprint: <slug>
   ---

   ## Current behavior
   <what actually happened — from the log>

   ## Expected behavior
   <what should have happened — from the UAT plan>

   ## Root cause
   <best guess based on error output and code context>

   ## Suggested fix
   <specific file + change suggestion>
   ```

4. **Present the summary:**
   ```
   ## UAT Results — <slug>

   | Plan | Scenarios | Pass | Fail | Skip | Status |
   |---|---|---|---|---|---|
   | 01 | 5 | 4 | 1 | 0 | FAILED |
   | 02 | 3 | 3 | 0 | 0 | PASSED |

   **Remediation files:** N created in .uat/remediation/
   ```

5. **Commit results:**
   ```bash
   git add .uat/results/ .uat/remediation/
   git commit -m "uat(<slug>): run — <pass-count> pass, <fail-count> fail"
   ```

## Hard rules

- **Never modify application code.** UAT observes and reports. Fixes happen in `/jira:execute` or manually.
- **Remediation files are dispatachable.** Each one is self-contained enough to hand to a sub-agent (via `/spawn`) for fixing.
- **Scripts are idempotent.** Running twice produces the same result if nothing changed.
- **Don't auto-fix.** Even obvious one-liners. Report, don't repair.
- **Always commit results.** Even on full-pass — the green record matters for regression tracking.
