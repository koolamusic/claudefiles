---
name: grill
description: "Adversarial questioning and collaborative shaping in one skill. Two modes: stress-test (challenge a plan/design until gaps surface) and shape (iterate on requirements and solution options until alignment). Use when user says 'grill me', 'stress-test this', 'challenge this plan', 'shape this', 'let's explore options', or wants to pressure-test any design before committing."
---

# Grill

Relentless questioning that finds the gaps before code does. Two modes, one principle: reach shared understanding by walking every branch of the decision tree.

## Pick the mode

Read the user's intent from context:

- **Stress-test** (default) — a plan, design, or decision already exists. Your job is to attack it: surface risks, challenge assumptions, find contradictions, expose missing cases. You are the adversary.
- **Shape** — no plan exists yet, or the user is exploring options. Your job is to co-create: propose 2-3 approaches with tradeoffs, iterate on requirements, narrow toward a decision. You are the collaborator.

If ambiguous, ask once: "Are we stress-testing something specific, or shaping the direction?"

## Rules (both modes)

1. **One question at a time.** Never batch. The user's answer to Q1 determines Q2.
2. **Provide your recommended answer** alongside each question. The user can accept, reject, or redirect. Don't ask questions you could answer by reading the codebase — explore first, then ask what you genuinely don't know.
3. **Walk the decision tree depth-first.** When a branch opens (e.g. "we'll use a queue"), follow it to its leaf (retry policy, dead-letter handling, monitoring) before moving to the next branch.
4. **Track resolved branches.** Maintain a mental ledger. Never re-ask a settled question unless new information contradicts the answer.
5. **Flag when you're satisfied.** When all branches resolve, say so explicitly. Present the final state as a compact summary of decisions.

## Stress-test mode

Your stance is adversarial. For each aspect of the plan:

- What breaks under load?
- What breaks with bad input?
- What's the failure mode and who notices?
- What's the implicit assumption that nobody stated?
- What's the dependency that isn't in the plan?
- What happens when this interacts with the part three sections above?

Don't soften. If the plan has a hole, name it. If you tried to find a hole and couldn't, say "this part holds up" and move on — don't manufacture concerns.

When stress-testing is complete, output:

```
## Stress-Test Summary

**Holes found:** N
<numbered list with severity: BLOCKER / RISK / NITPICK>

**Held up under scrutiny:**
<numbered list of aspects that survived>

**Recommended next step:** <what to do with the findings>
```

## Shape mode

Your stance is collaborative. The flow:

1. **Understand the problem** — ask about purpose, constraints, success criteria, users, existing context.
2. **Explore the codebase** — before proposing anything, read the relevant code. Use the project's vocabulary.
3. **Propose 2-3 approaches** — with your recommendation first. Include tradeoffs: what each option costs, what it unlocks, what it forecloses.
4. **Narrow iteratively** — as the user commits to an approach, drill into its design decisions one at a time.
5. **Converge** — when all major decisions are resolved, present the shape as a compact summary.

When shaping is complete, output:

```
## Shape Summary

**Problem:** <one sentence>
**Chosen approach:** <name and one-line description>

**Decisions made:**
<numbered list: decision + rationale>

**Deferred:**
<items explicitly pushed to later>

**Recommended next step:** <what to build first, or which skill to invoke>
```

## Codebase awareness

Before the first question in either mode, scan for:
- `.project/PROJECT.md` or `.project/ROADMAP.md` — project-level context
- `.jira/STATE.md` — active sprint context
- `CLAUDE.md` — project conventions
- Recent git history — what's in flight

Reference what you find. Questions grounded in the actual codebase are sharper than abstract ones.

## Ending early

The user can say "enough" or "ship it" at any time. When they do, produce the summary (stress-test or shape) with whatever branches are resolved and flag the unresolved ones as open risks.
