---
name: nit
description: "Adversarial bug finding using 3 isolated agents (Hunter, Skeptic, Referee) to find and verify real bugs with high fidelity. Based on bug-hunt by danpeg (https://github.com/danpeg/bug-hunt)."
argument-hint: "[path/to/scan]"
disable-model-invocation: true
---

# Nit - Adversarial Bug Finding

Run a 3-agent adversarial nit hunt on your codebase. Each agent runs in isolation.

## Target

The scan target is: $ARGUMENTS

If no target was specified, scan the current working directory.

## Execution Steps

You MUST follow these steps in exact order. Each agent runs as a separate subagent via the Agent tool to ensure context isolation.

### Step 1: Read the prompt files

Read these files using the skill directory variable:
- ${CLAUDE_SKILL_DIR}/prompts/hunter.md
- ${CLAUDE_SKILL_DIR}/prompts/skeptic.md
- ${CLAUDE_SKILL_DIR}/prompts/referee.md

### Step 2: Run the Hunter Agent

Launch a general-purpose subagent with the hunter prompt. Include the scan target in the agent's task. The Hunter must use tools (Read, Glob, Grep) to examine the actual code.

Wait for the Hunter to complete and capture its full output.

### Step 2b: Check for findings

If the Hunter reported TOTAL FINDINGS: 0, skip Steps 3-4 and go directly to Step 5 with a clean report. No need to run Skeptic and Referee on zero findings.

### Step 3: Run the Skeptic Agent

Launch a NEW general-purpose subagent with the skeptic prompt. Inject the Hunter's structured bug list (BUG-IDs, files, lines, claims, evidence, severity, points). Do NOT include any narrative or methodology text outside the structured findings.

The Skeptic must independently read the code to verify each claim.

Wait for the Skeptic to complete and capture its full output.

### Step 4: Run the Referee Agent

Launch a NEW general-purpose subagent with the referee prompt. Inject BOTH:
- The Hunter's full bug report
- The Skeptic's full challenge report

The Referee must independently read the code to make final judgments.

Wait for the Referee to complete and capture its full output.

### Step 5: Present the Nit Report

Display the Referee's final verified nit report to the user. Include:
1. The summary stats
2. The confirmed bugs table (sorted by severity)
3. Low-confidence items flagged for manual review
4. A collapsed section with dismissed bugs (for transparency)

If zero bugs were confirmed, say so clearly — a clean report is a good result.
