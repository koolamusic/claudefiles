---
description: "Classify failures from a warden run and write per-failure remediation files. Uses the JSONL audit trail to detect regressions vs newly failing assertions."
allowed-tools: Bash, Read, Write, Grep, Glob
argument-hint: "[run-id]"
---

Read the most recent (or specified) warden run's logs, classify each failing assertion, and write one remediation file per failure under `.warden/remediation/`.

## Parse the input

`$ARGUMENTS`:
- Empty: triage the most recent run.
- `<run-id>` (`YYYYMMDDTHHMMSS`): triage a specific run.

## Precondition

```bash
if [ ! -d .warden/runs ]; then
  echo "warden has no runs yet. Run /warden:run first."
  exit 1
fi
```

## Pick the run

```bash
if [ -n "$ARGUMENTS" ]; then
  RUN_ID="$ARGUMENTS"
else
  RUN_ID=$(ls -1 .warden/runs/*.md 2>/dev/null | sed -E 's|.*/||; s|\.md$||' | sort -r | head -1)
fi

if [ ! -f ".warden/runs/${RUN_ID}.md" ]; then
  echo "Run not found: $RUN_ID"
  exit 1
fi
```

## Gather failing assertions

Two sources:

**Per-plan logs** (full bash output) at `.warden/logs/<plan-name>-${RUN_ID}.log`. Grep these for `WARDEN_RESULT fail` lines and the surrounding context. Read up to 50 lines around each failure for the bash that produced it.

**JSONL audit trail** at `.warden/runs/asserts.jsonl`. Filter to this run's failures, plus the previous N runs' history for the same assertion names to detect regressions:

```bash
# Failures in this run
jq -c "select(.run == \"$RUN_ID\" and .status == \"fail\")" .warden/runs/asserts.jsonl

# All historical records per assertion (for regression detection)
jq -c "select(.name == \"<assertion-id>\")" .warden/runs/asserts.jsonl
```

## Classify each failure

For each failing assertion, decide a category:

| Category | Signals |
|---|---|
| `regression` | This assertion has passed in 2+ prior runs and just flipped to fail. JSONL history confirms it. |
| `env` | Failure detail mentions a missing env var (`$X is missing`), wrong endpoint (`connection refused`), or auth misconfig. |
| `setup` | A precondition failed before the actual subject under test (postgres unreachable, login failed, fixtures missing). The runner's preflight or `warden_wait_*` is the typical culprit. |
| `flake` | Same assertion has alternated pass/fail in recent runs. JSONL history shows the pattern. |
| `assertion` | The code under test produced a wrong result. Default classification when none of the above apply. |

## Investigate root cause

For non-flake, non-env failures, read the code under test. Use Grep to find the relevant source files based on what the assertion is verifying. Cite specific files and line numbers. Do not guess; read the code.

## Write a remediation file per failure

`Read` the template at `$CLAUDE_PLUGIN_ROOT/templates/remediation.md` for the format. Fill it in.

Path: `.warden/remediation/<NN>-<slug>.md` where:
- NN is the next available number (read existing files, increment)
- slug is derived from the assertion id (kebab-case)

For each remediation file, populate:
- The one-line summary in the heading
- Plan and step (assertion id is the step)
- First/last seen dates from JSONL
- Priority (P0/P1/P2/P3) inferred from severity and cascading impact
- Category (from classification above)
- Symptom: the verbatim `WARDEN_RESULT fail` line plus relevant log context
- Reproduction: minimal command to re-trigger
- Root cause: cited file:line references
- Cascading impact: other plans this likely blocks
- Suggested fix: concrete change

## Update HANDOFF.md

After writing all remediation files, update `.warden/HANDOFF.md`:
- Session date set to today
- Last run section with the run id, pass/fail counts per phase
- Open remediation section with the new files grouped by priority

Use Edit, not Write, to preserve any project-specific notes the user has added.

## Report back

Summarize:
- Run triaged
- Number of failures classified
- Breakdown by category (regression / assertion / setup / flake / env)
- Priority breakdown
- Path to the remediation/ directory

If there were regressions, surface them first; those need attention before new failures.
