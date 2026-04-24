<!--
SPRINT RESEARCH SYNTHESIS TEMPLATE
Synthesizes the three per-focus research files (research-codebase.md, research-patterns.md,
research-external.md) into a single document that feeds /jira:plan.

Convention inspired by:
- stellar/wallet-backend H-series — evidence grounding, anti-evidence discipline
- GSD (gsd-build/get-shit-done) — Don't Hand-Roll, Common Pitfalls with warning signs,
  SOTA Updates, confidence-tiered sources, research valid-until

Delete HTML comments and [guidance] brackets when filling. Sections marked "required if applicable"
can be omitted if genuinely not relevant — but note the omission in the Metadata footer.
-->

# Research: {{sprint_slug}}

**Date**: {{YYYY-MM-DD}}
**Domain**: {{primary technical area — e.g. backend/data-pipeline, library/typescript, frontend/mobile-ui}}
**Confidence**: {{HIGH | MEDIUM | LOW}}
**Valid until**: {{YYYY-MM-DD — 30 days stable, 7 days for fast-moving libs; state the reason in Metadata}}

## Summary

<!-- REQUIRED. 2-3 paragraphs. Executive summary for someone who will only read this section. -->

{{What was researched across the three focus areas. What the standard approach looks like after synthesis. What the planner needs to know before writing plans.}}

**Primary recommendation:** {{one-line actionable guidance that the planner starts from}}

## Architectural Responsibility Map

<!-- REQUIRED IF APPLICABLE. Skip for single-tier work. If skipped, note "Single-tier — all
capabilities reside in <tier>" and move on. -->

Map each capability in the brief to its architectural tier before planning. Prevents tier misassignment from propagating into plans.

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| {{capability from brief}} | {{Browser/Client, Frontend Server, API/Backend, CDN/Static, Database/Storage, or Infra}} | {{secondary or —}} | {{why this tier owns it}} |

## Codebase

<!-- REQUIRED. Sourced from research-codebase.md. -->

What exists today that's relevant. Cite `path:line` for every claim.

- **Existing:** {{what's already there and load-bearing}}
- **Would change:** {{files that need edits}}
- **Reference-only:** {{files to study but not modify}}

{{Detail — keep the headlines and citations from research-codebase.md; don't paraphrase into oblivion.}}

## Patterns & conventions

<!-- REQUIRED. Sourced from research-patterns.md. -->

How similar problems are solved elsewhere in this repo. Prefer imitating existing patterns over inventing.

- **To imitate:** {{pattern — with `path:line` where it lives and why it's the right model}}
- **To deliberately not imitate:** {{anti-pattern in the codebase — why it should not be copied forward}}

## Standard Stack

<!-- REQUIRED IF APPLICABLE. Skip when the sprint is a pure refactor or no new deps are considered.
Sourced primarily from research-external.md. -->

### Core

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| {{name}} | {{ver}} | {{what it does}} | {{why experts pick this}} |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| {{name}} | {{ver}} | {{what it does}} | {{use case}} |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| {{standard}} | {{alternative}} | {{when the alternative makes sense}} |

## Don't Hand-Roll

<!-- REQUIRED IF APPLICABLE. Skip when there's no "we could just build it" trap.
Combines local observations (research-patterns.md) with external solutions (research-external.md). -->

Problems that look simple but have established solutions. Building custom here is a known trap.

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| {{problem}} | {{what you'd build}} | {{library or in-repo primitive with `path:line`}} | {{edge cases, maintenance cost, prior incidents}} |

**Key insight:** {{one-line takeaway for the planner}}

## Common Pitfalls

<!-- REQUIRED. At least one entry. Format each as: What goes wrong / Why / How to avoid / Warning signs.
Sourced from research-external.md (docs, issues) and research-patterns.md (local near-misses). -->

### {{Pitfall 1 — short name}}

- **What goes wrong:** {{description}}
- **Why it happens:** {{root cause}}
- **How to avoid:** {{prevention strategy}}
- **Warning signs:** {{how to detect early — log pattern, metric, test that would catch it}}

### {{Pitfall 2 — short name}}

- **What goes wrong:** {{description}}
- **Why it happens:** {{root cause}}
- **How to avoid:** {{prevention strategy}}
- **Warning signs:** {{how to detect early}}

## SOTA Updates

<!-- OPTIONAL. Include when the work touches fast-moving libraries or frameworks. Skip otherwise. -->

What's changed recently that affects the approach:

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| {{old}} | {{new}} | {{date/version}} | {{what it means for this sprint}} |

**Deprecated:** {{anything in the repo or in common knowledge that's now outdated}}

## Risks & unknowns

<!-- REQUIRED. Things that need a decision in /jira:plan. Phrase each as a question the planner must answer. -->

- **{{risk label}}** — {{what's uncertain}}. {{What information would resolve it.}}
- **{{risk label}}** — {{what's uncertain}}. {{What information would resolve it.}}

## Open questions for planner

<!-- REQUIRED. One bullet per unresolved decision. These become CONTEXT.md D-XX entries after /jira:plan. -->

- {{question}}
- {{question}}

## Sources

<!-- REQUIRED. Tier every source. Never mix tiers. -->

### Primary (HIGH confidence)

Context7 library IDs, official docs, in-repo code with `path:line`.

- {{source}} — {{what it establishes}}
- {{source}} — {{what it establishes}}

### Secondary (MEDIUM confidence)

WebSearch results verified against an official source, community consensus with multiple agreeing sources.

- {{source}} — {{finding + how verified}}

### Tertiary (LOW confidence)

Single-source WebSearch, blog posts, inferred patterns. Mark for validation during planning or implementation.

- {{source}} — {{finding, what to validate}}

## Metadata

**Research scope:**
- Focus areas covered: codebase, patterns, external
- Any sections omitted and why: {{e.g. "SOTA Updates omitted — pure in-repo refactor, no external libs"}}

**Confidence breakdown:**
- Codebase findings: {{HIGH | MEDIUM | LOW}} — {{reason}}
- Patterns & conventions: {{HIGH | MEDIUM | LOW}} — {{reason}}
- Standard stack: {{HIGH | MEDIUM | LOW}} — {{reason}}
- Pitfalls: {{HIGH | MEDIUM | LOW}} — {{reason}}

**Valid-until reasoning:** {{why this date — e.g. "30 days: Next.js 16.x stable; would shorten to 7 if we were tracking the canary branch"}}

---

*Sprint: {{sprint_slug}}*
*Research completed: {{YYYY-MM-DD}}*
*Next step: `/jira:plan`*
