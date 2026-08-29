<!--
WAVE ISSUE TEMPLATE (single executable slice)
Source: one NN-PLAN.md from the active sprint.
Read ../GUIDE.md before filling — principle 13 (zero-context reader) governs this template.
The pushed body must contain no sprint slug, plan numeral, decision ID, or .jira/ path;
keep those in the draft frontmatter only. Delete comments and [guidance] brackets before pushing.
-->

Part of {{one-line description of the overall effort, in plain words}} — step {{N}} of {{total}}.

**Domain**: {{backend | library | frontend | integration | infra}}
**Depends on**: {{#N (short title), #M (short title) — or "nothing; can start now"}}
**Blocks**: {{#N (short title) — or "nothing"}}

## Goal

{{One sentence. What this step delivers, stated so someone who has not read the other steps understands it.}}

## Background

{{2-4 sentences a newcomer needs: what exists today, what is wrong or missing, and why this step is the fix. Define any project term on first use (e.g. "the registry — the JSON file that lists deployed contract addresses per network"). Link with full GitHub URLs to the files or docs that establish the current state.}}

Decisions already made that this step must respect (stated plainly, no IDs):

- {{decision as a plain sentence, with a full URL to where it is recorded if useful}}
- {{decision}}

Intentionally out of scope for this step:

- {{what is deferred and where it will happen — "handled in #N" or "a later effort"}}

## Changes

<!-- The concrete edits. backend/library: file + what changes and why. frontend: component + behaviour. Link each path to the default branch. -->

- [`{{path/to/file.ext}}`]({{full URL}}) — {{what changes and why}}
- [`{{path/to/file.ext}}`]({{full URL}}) — {{what changes and why}}
- [`{{path/to/file.ext}}`]({{full URL}}) — {{what changes and why}}

## Verification

<!-- The contract. Every item is a command or observation a stranger can run and answer yes/no. "Tests pass" is not an item; the specific test and what it asserts is. -->

- [ ] {{`command` → expected output}}
- [ ] {{observable behaviour}}
- [ ] {{manual/visual check — for frontend, name the page and the state in the screenshot}}

## Rollout

<!-- Pick one; delete the others. -->

N/A — direct merge, no flag or migration needed.

Behind `{{flag-name}}`. Default off. Enabled when {{condition}}.

Requires a schema change before merge: {{command}}. {{Backfill notes if any.}}

Ships together with {{#N / other change}}. Must land {{before / after / together}}.

Requires an operator action: {{who does what, where — e.g. "set `INDEX_CONTRACT_IDS` in the Railway service settings"}}.

## Risks

<!-- Include only real, non-obvious risk for this slice, and how the Verification list catches it. -->

- {{risk — caught by verification item N}}
