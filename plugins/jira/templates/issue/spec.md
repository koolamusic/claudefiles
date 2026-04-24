<!--
SPEC ISSUE TEMPLATE (sprint-level proposal)
Source: RESEARCH.md + all *-PLAN.md + CONTEXT.md from the active sprint.
Read ../GUIDE.md before filling. Delete comments and [guidance] brackets before pushing.
-->

**Sprint**: {{sprint-slug}}
**Domain**: {{backend | library | frontend | integration | infra | mixed}}

## Goal

{{One sentence. The outcome a reader can check against the finished system. Not "we'll refactor X" — instead "X handles Y under Z conditions".}}

## Why now

{{Motivation — constraint, deadline, incident, stakeholder ask. If this could be done next quarter instead, say what changes if it waits.}}

## Scope

### In

- {{bullet — what this sprint delivers}}
- {{bullet}}

### Out

- {{bullet — what's explicitly deferred, with a one-line reason}}
- {{bullet}}

## Approach

{{2-4 sentences sketching the shape of the work. Not the task list — the strategy. Reference the key decision in CONTEXT.md if the approach was contested: "chose X over Y (D-03) because <reason>".}}

## Waves

<!-- Roman numerals match the jira convention. One line per wave-plan file. -->

- **I.** `01-PLAN.md` — {{one-line goal}}
- **II.** `02-PLAN.md` — {{one-line goal}}
- **III.** `03-PLAN.md` — {{one-line goal}}

## Acceptance

<!-- Verifiable outcomes, not implementation checklists. "The tests pass" is not acceptance. -->

- [ ] {{a behavior a reader can observe in the running system}}
- [ ] {{a metric, contract, or invariant with a concrete threshold}}
- [ ] {{an integration surface that now behaves correctly}}

## Risks

<!-- The spec-shape equivalent of Anti-Evidence. What could go wrong, what's uncertain. -->

- **{{risk name}}** — {{what it is}}. {{Mitigation or open question.}}
- **{{risk name}}** — {{what it is}}. {{Mitigation or open question.}}

## Open Questions

<!-- Decisions not yet locked in CONTEXT.md. Remove this section if everything is decided. -->

- {{question — who needs to answer, by when}}

## References

- `RESEARCH.md` — findings this spec builds on
- `CONTEXT.md` — locked decisions (D-01 through D-{{N}})
- {{related issue / PR / doc}}
