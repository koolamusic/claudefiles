<!--
WAVE ISSUE TEMPLATE (single executable slice)
Source: one NN-PLAN.md from the active sprint.
Read ../GUIDE.md before filling. Delete comments and [guidance] brackets before pushing.
-->

**Sprint**: {{sprint-slug}}
**Wave**: {{Roman numeral, e.g. II}}
**Parent spec**: {{#N if the sprint issue exists, else sprint-slug}}
**Domain**: {{backend | library | frontend | integration | infra}}

## Goal

{{One sentence. What this wave delivers. Should fit inside the sprint's overall Goal without overlap with other waves.}}

## Context

{{2-3 sentences pointing the reader to the minimum they need to read: which RESEARCH.md section, which CONTEXT.md decisions (D-XX), which parent plan files. Don't duplicate content — link to it.}}

- Depends on: {{prior wave(s) or external work}}
- Decisions locked in: {{D-XX, D-YY}}
- Deferred from this wave: {{what's intentionally out of scope}}

## Changes

<!-- The concrete edits. For backend/library: file:line + what changes. For frontend: component + behavior. -->

- `{{path/to/file.ext}}` — {{what changes and why}}
- `{{path/to/file.ext}}` — {{what changes and why}}
- `{{path/to/file.ext}}` — {{what changes and why}}

## Verification

<!-- How you'll know this wave delivered. Nyquist-style: every acceptance item has a test or observable check. -->

- [ ] {{test or observable behavior — e.g. "new unit test covers the null-input case"}}
- [ ] {{integration or E2E check}}
- [ ] {{manual check, if any — for frontend this is often the visual confirmation}}

## Rollout

<!-- How this lands. Pick one; delete the others. -->

<!-- No rollout considerations: -->
N/A — direct merge, no flag or migration needed.

<!-- Feature flag: -->
Behind `{{flag-name}}`. Default off. Ramp plan: {{when/how to enable}}.

<!-- Migration: -->
Requires schema push before merge: {{prisma migrate dev / drizzle push / ...}}. {{Backfill notes if any.}}

<!-- Coordinated release: -->
Ships with {{related PR / other service change}}. Must land {{before / after / together with}}.

## Risks

<!-- Optional for waves. Include only if this slice has non-obvious risk not covered by the spec. -->

- {{risk — and how verification catches it}}
