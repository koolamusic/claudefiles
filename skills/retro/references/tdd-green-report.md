# TDD GREEN Phase: retro skill

## Gap Coverage Matrix

| # | Gap (from RED) | Addressed? | Enforcement Strength | Remaining Loopholes |
|---|----------------|------------|---------------------|-------------------|
| 1 | Structured 10-section template with tables | Yes | Strong | The template exists with exact table schemas (Success Criteria with Status/Evidence, Decisions with Options/Choice/Rationale, Issues with Severity/Resolution/Time Impact, Metrics with Planned/Actual/Delta). Step 4 enumerates all 10 sections by number. Step 5 Completeness Check mandates "every table has at least 1 data row." The `{{variable}}` placeholders in the template make structure unambiguous. **Loophole:** An agent could fill a table with a single vague row (e.g., "General work | Done | N/A") to technically pass the check while adding no value. Step 5 bans "N/A for entire sections" but not N/A in individual cells. |
| 2 | Provider probing and merging | Yes | Strong | References/providers.md specifies exact probe logic (file existence checks, `gh auth status`), useful commands per provider, and the merge precedence rule "Never discard data from a lower-priority provider." First-run init (config.md Steps 1-3) probes systematically. **Loophole:** The skill says "merge" but never defines a concrete merge algorithm. When GSD says "5 requirements completed" and git shows 6 revert commits, the skill doesn't specify how to reconcile the contradiction — it just says cross-reference. An agent could merge superficially (list both data points in different sections without reconciliation). |
| 3 | Manual gap-filling questions | Yes | Strong | Providers.md defines 7 specific prompts with exact wording. The manual provider is "always enabled, cannot be disabled." Step 5 adds a hard floor: "If fewer than 3 manual questions were asked across the whole retrospective, you likely skipped subjective context. Go back and ask about surprises, failures, and forward risks at minimum." **Loophole:** The 3-question minimum is low. In Scenario 3 (minimal project), manual is the primary provider and should drive 5-7 questions. An agent could ask 3 shallow questions and technically pass. Also, the skill says "ask only for gaps" — an agent could rationalize that git data already covers everything and ask only the minimum 3. |
| 4 | Config infrastructure | Yes | Strong | Config.md defines the full JSON schema with every field documented. First-run initialization is a 6-step procedure with specific probe checks, priority ordering for phase_definition, and exactly 2 required user questions. `/retro init` is an explicit command. **Loophole:** None significant. This is the most prescriptive part of the skill. The only gap is that the skill doesn't specify what happens if a user answers the 2 questions ambiguously (e.g., "whatever you think is best" for trigger mode). |
| 5 | Output directory and naming | Yes | Strong | Step 6 specifies `<retrospective_dir>/phase-<N>-<slug>.md` with default `.retrospective/`. Config has `retrospective_dir` field. "Overwrite if exists" handles idempotency. **Loophole:** The slug derivation is not specified. What slug does a git-tag-based phase get? What about Scenario 3 where there's no phase name? An agent could produce inconsistent slugs across retros. |
| 6 | Stakeholder report | Yes | Medium | Step 7 generates it when `stakeholder_report.auto_generate` is true. The template exists with tables for Objectives/Results, Key Metrics, Decisions, Risk Register, and a Next Phase Preview with Readiness Assessment. **Loophole:** The default config has `auto_generate: true`, so this fires by default — good. But the skill says "Optional" in the step header. An agent motivated to cut corners could interpret "optional" as permission to skip. The enforcement is config-driven, not mandate-driven: if the agent doesn't properly initialize config, this never fires. |
| 7 | Cumulative SUMMARY.md | Yes | Medium | Step 6 (second instance — note the duplicate numbering) handles this when `summary_tracker.auto_update` is true. SUMMARY-TEMPLATE.md defines the structure with cross-phase learnings, compounding risks, cumulative risk register, and project-level decisions. **Loophole:** The skill says "update" the SUMMARY but doesn't specify the update algorithm. Adding a row to the Phase Completion Status table is clear, but "Cross-Phase Learnings → Recurring Themes" requires the agent to synthesize across all previous retros. An agent could append the current phase's learnings without actually identifying recurring patterns. Also, the duplicate Step 6 numbering could cause an agent to skip one of the two Step 6s. |
| 8 | Honesty-first tone | Yes | Strong | Multiple reinforcing mechanisms: Core Principle 2 ("Honest by default — Never omit negative findings"), Step 4 ("Surface the bad and the ugly prominently. Sugarcoating defeats the purpose."), Step 5 Honesty Audit ("Sections 2, 6, 7, 8 must not lead with positives if negatives exist. Check for softening language: 'challenges', 'despite difficulties', 'evolved the approach'. Replace with direct language."), and the template's Findings section has "Unexpected findings are the most valuable part of a retrospective. Prioritize these." Step 5 also mandates confidence scores that "reflect reality — if 2 of 5 requirements failed, Quality is not 4." **Loophole:** The softening-language blocklist is incomplete. Common agent euphemisms not listed: "learning opportunity", "room for improvement", "iterative process", "minor setback", "partially achieved", "adjusted scope." An agent could dodge the specific banned phrases while still sugarcoating with unlisted synonyms. |
| 9 | Idempotency | Yes | Strong | Step 6: "Overwrite if exists." Clear and unambiguous. **Loophole:** None for the phase retro file. However, SUMMARY.md update is "update" not "overwrite" — if the update logic fails and the agent appends a duplicate phase row, there's no dedup instruction. |
| 10 | Hook and trigger behavior | Yes | Strong | Two concrete shell scripts ship with the skill. `retro-trigger.sh` watches PostToolUse for STATE.md edits and git tag commands, reads config mode, and either auto-triggers (exit 2 with message), prompts (exit 2 with message + writes pending_retro), or silently passes (exit 0). `retro-reminder.sh` checks pending_retro on SessionStart. `/retro init` registers both hooks in `.claude/settings.json`. **Loophole:** The git tag detection regex (`^git\s+tag\s+[^-]`) misses annotated tags (`git tag -a v2.0 -m "Release"`) because `-a` starts with `-`. This means annotated tags (the most common release tag pattern) silently bypass the hook. Also, the hook doesn't detect GitHub milestone closures — only GSD STATE.md edits and git tags. |

## Scenario Trace-Through

### Scenario 1: Plain Git Repo, No GSD — "Write a retrospective for work since the last tag"

**Skill execution path:**
1. Step 1: Load config. Missing → first-run init fires.
   - Probe: `.planning/STATE.md` absent → gsd disabled. `.git/` present → git enabled. `gh auth status` → github enabled/disabled per result. Manual always on.
   - Phase definition: No GSD → check git tags → tags present → `git_tag`.
   - Ask user 2 questions (trigger mode, custom label).
   - Write config.
2. Step 2: Phase provided ("since v1.0") → use git tag boundary `v1.0..HEAD`.
3. Step 3: Query git provider (commits, diff stats, messages). Query GitHub if enabled (PRs merged, issues closed). Query manual for gaps.
4. Step 4: Fill all 10 sections from template. Git provides metrics, commit-derived decisions/issues. Manual fills objective, success criteria, surprises, learnings, forward risks.
5. Step 5: Completeness check — verify all sections populated, tables have data rows, no placeholders, honesty audit, confidence scores. Manual question count check (must be >= 3).
6. Step 6: Write to `.retrospective/phase-1-<slug>.md`.
7. Step 6 (second): Update SUMMARY.md.
8. Step 7: Generate stakeholder report if auto_generate is true.

**Expected output:** Full 10-section retro with tables, stakeholder report, SUMMARY.md, and config file. All in `.retrospective/`.

**Remaining risks:**
- If the agent rushes through first-run init and doesn't wait for user answers to the 2 questions, config gets defaults. Defaults are reasonable (mode: prompt, manual: always on), so this is low risk.
- The agent might interpret "since v1.0" as a single tag boundary and not know how to generate a phase number. The skill doesn't specify how to map arbitrary tag ranges to phase numbers — it says `/retro <N>` for phase N, but v1.0..HEAD isn't necessarily "phase 1."

### Scenario 2: GSD Project, Phase 3 Just Completed — "Generate a retro for phase 3"

**Skill execution path:**
1. Step 1: Config exists (or first-run creates it with gsd, git, github all detected).
2. Step 2: Phase 3 specified → find `.planning/phases/03-data-migration/`.
3. Step 3: All providers fire:
   - GSD: reads STATE.md, ROADMAP.md, REQUIREMENTS.md, phase-specific CONTEXT/PLAN/SUMMARY/VALIDATION files. Gets structured requirements, deviations, decisions, metrics.
   - GitHub: queries merged PRs and closed issues for the phase timeframe. Gets review comments, labels, collaboration data.
   - Git: gets diff stats, commit messages, revert commits identified.
   - Manual: asks about surprises, failures, forward risks (gaps after above).
4. Step 4: Merge per precedence (GSD → GitHub → Git → Manual). Fill all 10 sections. The descoped requirement appears in Section 7 (Requirement Completion table with explicit status). Reverted commits appear in Section 6 (Issues table with Severity/Resolution/Time Impact). Reversed architectural decision in Section 5 (Decisions table with Options/Choice/Rationale showing both the original and reversal).
5. Step 5: Completeness check catches any empty sections. Honesty audit checks Sections 2, 6, 7, 8 don't lead with positives.
6. Steps 6-7: Write retro, SUMMARY.md, stakeholder report.

**Expected output:** Rich multi-provider retro with the descoped requirement called out explicitly in the Requirement Completion table, reverts analyzed with root cause in the Issues table, and cross-referenced data from all three automated providers.

**Remaining risks:**
- The merge precedence says "never discard" but doesn't specify how to present conflicting data. If GSD SUMMARY says "4 tasks completed" but git shows reverts that undermine that claim, an agent might present both without flagging the contradiction.
- The skill reads GSD's SUMMARY file which already contains some analysis. An agent might copy-paste GSD's self-assessment rather than independently assessing against the raw evidence. The skill doesn't explicitly say "don't parrot the GSD SUMMARY — verify it."

### Scenario 3: Minimal Project, No Tags, No GSD — "I just finished a sprint, write a retro"

**Skill execution path:**
1. Step 1: No config → first-run init. Probes: no GSD, git exists but no tags, no GitHub milestones → phase_definition falls through to `manual`. Asks 2 questions (trigger mode, custom label — user might say "sprints" here).
2. Step 2: No phase number given, no automated boundary → must ask user via manual provider: "What work does this phase cover? (date range, commits, description)."
3. Step 3: Git provides whatever it can from the specified range. Manual is the primary provider — the 7 gap-filling prompts become the backbone. Agent should ask about: objective, success criteria, surprises, what didn't go well, forward risks, stakeholder context, plus the phase boundary question. That's 6-7 questions.
4. Step 4: Fill template primarily from user answers. Git provides quantitative metrics (commit count, files changed).
5. Step 5: Completeness check. Manual question count should be well above 3. All sections should have content from user answers.
6. Steps 6-7: Write retro, SUMMARY.md, stakeholder report.

**Expected output:** A full 10-section retro driven primarily by user input, with git metrics supplementing. The retro structure is identical to a data-rich project — same tables, same sections.

**Remaining risks:**
- This is where the "ask only for gaps" instruction conflicts with reality. With only git available, almost everything is a gap. An agent could still rationalize that git commit messages provide enough for Decisions, Findings, and Observations, reducing manual questions to the minimum 3. The skill should be clearer: when the only automated provider is git, manual questions should cover ALL sections that git can't populate with structured data (which is most of them).
- The Edge Cases section (Section 4) is particularly vulnerable. Even with manual prompting, the generic gap-filling questions don't specifically ask about edge cases. The 7 prompts cover objective, success criteria, surprises, failures, risks, stakeholder context, and phase boundary — but not edge cases or decisions explicitly. An agent might fill Edge Cases with "None identified" or a thin entry.

### Scenario 4: Honesty Pressure — Phase With Clear Failures

**Skill execution path:**
1. Steps 1-3: Standard flow. GSD SUMMARY contains failure data. Git shows 4 reverts, fix/hotfix commits. GitHub has 2 critical bug issues.
2. Step 4: Template filling. The key sections:
   - Section 2 (Findings): "Unexpected findings are the most valuable." The production bug, estimation failure, and architectural reversal are all unexpected findings that must be prioritized per the template instruction.
   - Section 6 (Risks & Issues): Issues table with Severity/Resolution/Time Impact for each problem. Forward-Looking Risks table flagging recurrence patterns.
   - Section 7 (Metrics): Planned vs Actual table showing 3x time overrun with Delta column. Requirement Completion table showing 2 of 5 as FAIL with evidence.
   - Section 8 (Learnings): What Didn't Work and What We'd Do Differently sections.
   - Section 10: Confidence scores — with 2/5 requirements failed, Quality cannot be 4+ per Step 5 rules.
3. Step 5: Honesty audit is the critical gate:
   - Sections 2, 6, 7, 8 must not lead with positives if negatives exist.
   - Banned phrases: "challenges", "despite difficulties", "evolved the approach."
   - Confidence scores must reflect reality.
   - Manual questions asked: at minimum, about failures and forward risks.

**Expected output:** A retrospective that leads with the production bug, the 3x overrun, the 2 failed requirements, and the reversed architecture decision. Confidence scores of 1-2/5 for Quality. Issues table with severity ratings. No softening language.

**Remaining risks:**
- The banned softening language list has 3 entries. Common agent euphemisms not covered: "learning opportunity", "room for improvement", "adjusted timeline", "scope refinement", "partially met", "incremental progress despite headwinds." An agent could avoid the 3 banned phrases while still writing diplomatically.
- The honesty audit says sections "must not lead with positives if negatives exist" but doesn't define "lead." Does the section heading count? The first sentence? The first subsection? An agent could put "What Worked Well" first in Section 8 (it IS first in the template order) and argue the template order is authoritative.
- The confidence score rule ("if 2 of 5 requirements failed, Quality is not 4") is one example. It doesn't generalize. What if 1 of 5 failed but it was the critical one? An agent could score Quality as 3 and technically not violate the stated rule.

### Scenario 5: Config and Infrastructure — "Set up retrospectives for this project"

**Skill execution path:**
1. `/retro init` command maps to the first-run initialization flow in config.md.
2. Step 1 (Probe): Check `.planning/STATE.md` (exists → gsd enabled), `.git/` (exists → git enabled), `gh auth status` (succeeds → github enabled). Manual always on.
3. Step 2 (Check existing): Look for `.retrospective/` directory. None → create it.
4. Step 3 (Phase definition): GSD available → `gsd_phase`. Priority chain followed.
5. Step 4 (Ask user): Two questions — trigger mode and custom label. Both with specific wording provided.
6. Step 5 (Write config): Full JSON schema written to `.claude/retrospective.config.json`.
7. Step 6 (Confirm): Display config summary. If a completed phase exists, proceed to first retro.
8. Hook registration: `/retro init` also registers both hooks in `.claude/settings.json` per the SKILL.md hook section.

**Expected output:** Config file with all providers correctly detected, `.retrospective/` directory created, default templates available, hooks registered in project settings, and a clear summary shown to user.

**Remaining risks:**
- The hook registration instruction says "register both hooks automatically if the project's `.claude/settings.json` doesn't already have them." But it doesn't specify merge behavior. If settings.json already has PostToolUse hooks for other tools, the agent needs to merge, not overwrite. The skill doesn't specify this merge strategy.
- Template deployment is implicit. The skill references `_templates/` as "built-in defaults" but doesn't say whether to copy them to the project's `.retrospective/` directory or reference them from the skill's install location. If the skill is installed globally at `~/.claude/skills/retro/`, the template paths in config need to resolve correctly. This path resolution is not specified.

## Loopholes Found

1. **Annotated tag detection failure.** The `retro-trigger.sh` regex `^git\s+tag\s+[^-]` rejects commands starting with flags like `-a`. Since `git tag -a v2.0 -m "Release 2.0"` is the standard way to create release tags, the hook silently misses the most common release workflow. This is a functional bug, not a loophole.

2. **Softening language blocklist is too short.** Only 3 phrases are banned: "challenges", "despite difficulties", "evolved the approach." Agent euphemism vocabulary is much larger. The check should either be a broader pattern (e.g., "any language that reframes a failure as a positive") or the list should be expanded to 10-15 common patterns.

3. **Merge algorithm is undefined.** "Never discard data from a lower-priority provider" and "cross-reference" are instructions to merge, but without a concrete algorithm. When GSD says "completed" and git evidence says "reverted," the skill doesn't mandate that the agent flag the contradiction. An agent could present both data points in separate sections without reconciliation.

4. **Duplicate Step 6 numbering.** Steps 6 and 6 (retro file write and SUMMARY.md update) share the same number. An agent parsing the execution flow sequentially could miss the second Step 6 entirely, never updating SUMMARY.md.

5. **Slug derivation unspecified.** The naming convention `phase-<N>-<slug>.md` doesn't define how to generate the slug from phase data. This leads to inconsistent filenames across retros.

6. **Edge Cases section has no dedicated manual prompt.** The 7 gap-filling prompts in providers.md cover objective, success criteria, surprises, failures, risks, stakeholder context, and phase boundary — but not edge cases. For projects where automated providers don't surface edge cases (most projects), this section will be thin or empty.

7. **Template ordering undermines honesty-first in Section 8.** The Learnings template lists "What Worked Well" before "What Didn't Work." The honesty audit says "must not lead with positives if negatives exist" but the template's own ordering puts positives first. This creates an ambiguity an agent will exploit.

8. **Confidence score calibration is example-based, not rule-based.** The skill gives one calibration example (2/5 requirements failed → Quality is not 4). It doesn't provide a general scoring rubric. Agents will inflate scores in edge cases not covered by the single example.

9. **No GitHub milestone close detection in hooks.** The config lists `github:milestone-close` as a valid auto-trigger event, but neither hook script implements detection for it. This trigger is documentation-only with no enforcement mechanism.

10. **"Ask only for gaps" creates a rationalization vector.** When automated providers return partial data, an agent can claim the gaps are filled and skip manual questions. The 3-question minimum floor is too low for data-poor scenarios like Scenario 3.

## Recommendations

### High Priority (functional bugs or easily exploited loopholes)

1. **Fix annotated tag regex** in `retro-trigger.sh`. Change `^git\s+tag\s+[^-]` to something like `^git\s+tag\s+(-[asm]\s+)*[^-]` or parse more carefully to handle `git tag -a <name>` patterns.

2. **Fix duplicate Step 6 numbering** in SKILL.md. Renumber the SUMMARY.md update step to Step 7 and shift stakeholder report to Step 8. This eliminates the risk of an agent skipping the summary update.

3. **Expand the softening language blocklist** in the Step 5 honesty audit. Add at minimum: "learning opportunity", "room for improvement", "adjusted scope/timeline", "partially achieved/met", "minor setback", "incremental progress", "opportunity for improvement", "refinement." Or rephrase as a general principle: "Any language that reframes a negative outcome as positive, neutral, or as a growth opportunity is prohibited. State what failed, why, and what it cost."

4. **Add a manual prompt for edge cases** to the provider gap-filling table in providers.md. Something like: "Were there any non-obvious scenarios or boundary conditions you encountered?"

### Medium Priority (strengthens enforcement)

5. **Define a minimum manual question count relative to data richness.** Replace the flat "3 minimum" with: "If only git and manual providers are active, minimum 5 manual questions. If GSD or GitHub provide structured data, minimum 3." This scales the floor to the scenario.

6. **Add a contradiction-flagging instruction** to the merge rules: "When data from different providers conflicts (e.g., GSD reports completion but git shows reverts of that work), the retrospective must explicitly flag the contradiction in the Findings section under Unexpected, not silently present both."

7. **Reorder Section 8 template** to put "What Didn't Work" before "What Worked Well", or add an explicit note: "If negatives exist, present What Didn't Work first regardless of template ordering."

8. **Add a confidence scoring rubric** to the template or Step 5:
   - 5: All requirements met, no significant issues
   - 4: All requirements met, minor issues resolved
   - 3: Most requirements met, some issues outstanding
   - 2: Significant requirements unmet or major issues
   - 1: Critical failures, phase objectives not achieved

### Low Priority (polish)

9. **Specify slug derivation**: "Slug is the phase name lowercased, spaces replaced with hyphens, non-alphanumeric characters removed, truncated to 50 characters. If no phase name, use the phase number only: `phase-<N>.md`."

10. **Specify template path resolution**: "Templates referenced in config are resolved relative to the skill's install directory (`~/.claude/skills/retro/`). Custom templates are resolved relative to the project root."

11. **Add a note about settings.json merge on hook registration**: "When registering hooks in `.claude/settings.json`, merge into existing hook arrays. Do not overwrite existing hooks for the same trigger."
