# Why This Skill Exists

## The Problem

Retrospectives are the only structured feedback loop between execution and visibility. Without them:

- **Knowledge evaporates between sessions.** Claude Code conversations are ephemeral. What went wrong in phase 2 is gone by phase 5 unless someone wrote it down. Context resets mean the same mistakes get repeated.

- **Stakeholders are blind.** Engineering work happens in commits, PRs, and planning files that non-technical stakeholders never see. Without a translation layer, there is no visibility into what actually happened — only what was planned.

- **Agents sugarcoat by default.** When asked to "write a retrospective," agents produce diplomatic summaries that lead with positives and bury failures. This is the opposite of useful. The whole point of a retrospective is to surface what went wrong so it can be fixed.

- **No structure means no comparability.** Freeform retros from different phases can't be compared. You can't track whether estimation accuracy improved, whether the same risks keep recurring, or whether decisions from phase 1 are still valid in phase 6.

## What Happens Without This Skill

We tested this (see `references/tdd-red-report.md`). Without the skill, agents:

1. Produce 3-5 prose paragraphs instead of 10 structured sections with tables
2. Use whatever data source is most obvious, ignoring available providers
3. Ask 0-2 generic questions instead of probing for subjective context
4. Use softening language ("challenges", "evolved the approach") instead of stating failures directly
5. Write to random locations with inconsistent naming
6. Never generate stakeholder reports or cumulative summaries
7. Never create config, so every retrospective is a one-off with no memory of preferences
8. Inflate confidence scores or omit them entirely

## Why Structure Matters

The 10-section template with mandatory tables is not bureaucracy. Each section exists because freeform retros consistently miss it:

| Section | Why it's mandatory |
|---------|-------------------|
| Phase Context | Without explicit scope in/out, retrospectives evaluate work that wasn't in scope |
| Findings | Unexpected findings are the most valuable output — agents skip them without a dedicated section |
| Observations | Patterns across work only surface when you look for them explicitly |
| Edge Cases | Non-obvious scenarios get forgotten immediately. This is institutional memory. |
| Decisions Made | Without an audit trail, the same debates happen every phase |
| Risks & Issues | Forward-looking risks are always omitted without a dedicated section. Agents only report backward. |
| Metrics & Progress | Planned vs actual with deltas is the only way to track estimation accuracy over time |
| Learnings | "What we'd do differently" is where process improvement lives. Agents skip it to stay positive. |
| Artifacts | Teams lose track of what was produced. A simple table prevents "where is that script?" |
| Stakeholder Highlights | The translation layer. Confidence scores force honest self-assessment. |

## Why Honesty Is Enforced

The skill has an explicit honesty audit in the completeness check because agent default behavior is to be polite. Polite retrospectives are worthless. The skill:

- Bans softening language in failure-heavy sections
- Requires confidence scores that reflect reality (2 of 5 requirements failed = Quality is not 4/5)
- Mandates that unexpected findings and failures get priority placement
- Requires a minimum of 3 manual questions to capture subjective context agents can't derive

## Why Hooks Exist

Without enforcement, retrospectives don't happen. The hooks (`retro-trigger.sh`, `retro-reminder.sh`) exist because:

- In `auto` mode: the retrospective generates without anyone thinking about it
- In `prompt` mode: if deferred, the reminder persists across sessions via `pending_retro` in config
- In `manual` mode: no enforcement, but the infrastructure is ready when `/retro` is invoked

## Who This Is For

- **Future agents** working on the same project across context resets — the retrospective is their briefing document
- **Stakeholders** who need visibility without reading commits — the stakeholder report is their interface
- **The engineer** who wants to remember what actually happened, not what they think happened
