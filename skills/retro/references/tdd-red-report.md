# TDD RED Phase: retro skill

## Overview

This report documents the expected behavior of a Claude Code agent asked to produce retrospectives WITHOUT the `retro` skill loaded. The goal is to establish a baseline of failures, shortcuts, and rationalizations that the skill must correct in the GREEN phase.

The skill specifies: 10 mandatory sections with tables, a config system with provider probing, a `.retrospective/` output directory, cumulative SUMMARY.md tracking, optional stakeholder reports, an honesty-first tone, and a manual-fills-the-gaps principle. None of this is default agent behavior.

---

## Scenarios Tested

### Scenario 1: Plain Git Repo, No GSD — "Write a retrospective for work since the last tag"

**Setup:** A typical open-source or side project. Has git tags (e.g., `v1.0`, `v1.1`). No `.planning/` directory. No GSD. GitHub remote exists. User says: *"Write a retrospective for the work done since v1.0."*

**Expected agent behavior WITHOUT skill:**
- Runs `git log v1.0..HEAD --oneline` and `git diff --stat v1.0..HEAD`
- Produces a freeform markdown summary with 3-5 sections (e.g., "Summary", "Changes", "Notable Items")
- Writes the file to the project root or asks where to put it
- Does not ask the user any manual questions about surprises, failures, or learnings
- Does not generate a stakeholder report or cumulative summary
- Does not create or look for a config file

**Specific failures:**
- Missing 6-8 of the 10 required sections. Likely omits: Edge Cases, Decisions Made (as structured table), Observations (patterns/anomalies), Artifacts table, Stakeholder Highlights with confidence scores
- No structured tables. Decisions appear as prose bullets, not as a table with Options Considered / Choice / Rationale columns
- No Success Criteria table with Status and Evidence columns
- No Planned vs Actual metrics comparison
- Output written to project root (e.g., `RETROSPECTIVE.md`) not `.retrospective/phase-1-<slug>.md`
- No SUMMARY.md created or updated
- No stakeholder report generated
- No `.claude/retrospective.config.json` created
- No provider probing (does not check `gh auth status`, does not look for `.planning/`)
- Positive-leaning tone: likely leads with accomplishments, buries or omits issues

**Likely rationalizations:**
- "I've summarized the key changes and highlights" (skipping the structured template)
- "I focused on the most relevant information" (justifying omission of sections with no obvious data)
- "Since this is a simple project, a streamlined format is more appropriate" (inventing a reason to skip structure)

---

### Scenario 2: GSD Project, Phase 3 Just Completed — "Generate a retro for phase 3"

**Setup:** A project using GSD. `.planning/STATE.md` shows phase 3 complete. `.planning/phases/03-data-migration/` has CONTEXT, PLAN, SUMMARY, and VALIDATION files. The phase had two reverted commits and a requirement that was descoped mid-phase. GitHub has 4 merged PRs and 2 closed issues for this work.

**Expected agent behavior WITHOUT skill:**
- Reads some GSD files (likely STATE.md and the phase SUMMARY)
- May or may not read ROADMAP.md or REQUIREMENTS.md
- Produces a markdown summary that partially mirrors the GSD SUMMARY format
- Does not merge data from git history or GitHub PRs/issues alongside GSD data
- Does not use the 10-section template
- Does not generate a stakeholder report
- Does not update a cumulative SUMMARY.md
- Writes output to `.planning/` or project root, not `.retrospective/`
- May not surface the descoped requirement prominently
- Reverted commits get mentioned in passing, not in a Risks & Issues table with severity

**Specific failures:**
- No provider merging: GSD data read in isolation. The 4 merged PRs and their review comments (GitHub provider) are ignored. Git diff stats not cross-referenced with GSD metrics
- No Requirement Completion table (Req ID, Description, Status, Evidence) despite REQUIREMENTS.md being available
- Missing Forward-Looking Risks section
- No confidence scores in Stakeholder Highlights
- Descoped requirement likely downplayed: "Phase 3 focused on the core migration tasks" rather than explicitly stating what was cut and why
- Reverted commits listed but not analyzed for root cause or time impact
- No config file created, so no record of which providers were used or how phases are defined
- No idempotency: if run twice, may create a duplicate file rather than overwriting

**Likely rationalizations:**
- "The GSD SUMMARY already captures the key outcomes" (justifying not enriching with other providers)
- "I've included the most important findings from the phase" (justifying missing sections)
- "The descoped requirement can be addressed in a future phase" (deflecting rather than documenting the deviation)

---

### Scenario 3: Minimal Project, No Tags, No GSD — "I just finished a sprint, write a retro"

**Setup:** A small project. Git repo with 30 commits on main, no tags, no branches, no GSD, no GitHub milestones. User simply says *"I just finished a sprint, write a retro."*

**Expected agent behavior WITHOUT skill:**
- Has no clear phase boundary. Either uses all commits or asks "which commits?"
- Produces a brief, freeform summary of recent work
- Does not probe for available providers
- Does not ask structured manual questions to fill gaps (objective, success criteria, what surprised you, what didn't go well, forward risks)
- Generates a single file, no stakeholder report, no summary tracker
- Likely writes 200-400 words of prose

**Specific failures:**
- No phase boundary determination logic. Without the skill's provider precedence (try tags, then merge commits, then ask user), the agent either guesses or asks a vague question
- Zero structured tables. Everything is prose paragraphs
- The manual provider is the PRIMARY source here (the user is the main data source), but the agent asks 0-2 questions instead of the 6-7 gap-filling prompts the skill defines
- No Edge Cases section (the agent has no concept that edge cases are a retrospective category)
- No Artifacts table
- No Observations section with patterns/anomalies/technical notes
- No confidence scores anywhere
- Output directory is ad hoc
- No config initialization — the agent has no concept of `.claude/retrospective.config.json`

**Likely rationalizations:**
- "Based on the available git history, here's a summary of the sprint" (pretending git log alone is sufficient)
- "Since there's limited structured data, I've kept the retrospective concise" (justifying skipping sections rather than asking the user)
- "Feel free to add any additional context" (pushing the work back to the user instead of actively asking questions)

---

### Scenario 4: Honesty Pressure — Phase With Clear Failures

**Setup:** A GSD project where phase 2 had significant problems. The SUMMARY file notes: 2 of 5 requirements failed verification, a critical bug was discovered in production, the phase took 3x longer than estimated, and a core architectural decision was reversed mid-phase. Git history shows 4 revert commits, multiple `fix:` and `hotfix:` commits. Two GitHub issues are labeled `bug` and `critical`.

**Expected agent behavior WITHOUT skill:**
- Reads the GSD SUMMARY which contains some failure data
- Produces a retrospective that acknowledges problems but structures them as "challenges overcome"
- Leads with what went well, treats failures as secondary
- Uses softening language: "encountered some challenges", "required additional iteration", "evolved the approach"
- Does not quantify the time impact of failures
- Does not create a severity-rated Issues table
- Does not assign confidence scores that reflect the actual state (would likely score 3-4/5 when the real score is 1-2/5)

**Specific failures:**
- Tone inversion: the skill says "surface the bad and the ugly prominently" and "sugarcoating defeats the purpose." Without the skill, the agent's default politeness dominates
- No Issues Encountered table with Severity / Resolution / Time Impact columns
- Failed requirements not presented in a Requirement Completion table showing explicit FAIL status with evidence
- The reversed architectural decision not documented in a Decisions table showing the original choice, the reversal, and the rationale
- Forward-Looking Risks section missing or toothless — does not flag that the same patterns (estimation, architecture churn) may recur
- Learnings section says "what worked well" first, "what didn't" second and briefly. The skill's template puts these in order but the honest-by-default principle means unexpected findings and failures get priority treatment
- Production bug not called out with severity or customer impact
- Planned vs Actual table missing — the 3x time overrun is mentioned in prose but not quantified in a table with Delta column

**Likely rationalizations:**
- "Despite some challenges, the team made significant progress" (the classic sugarcoat opener)
- "The architectural pivot ultimately led to a better solution" (reframing a failure as a positive without acknowledging the cost)
- "Estimation accuracy improved over the course of the phase" (deflecting from the 3x overrun)
- "The critical bug was quickly identified and resolved" (minimizing a production incident)

---

### Scenario 5: Config and Infrastructure — "Set up retrospectives for this project"

**Setup:** A project with GSD, git, and GitHub all available. User says *"Set up retrospectives for this project"* before any retrospective has been generated.

**Expected agent behavior WITHOUT skill:**
- Creates a directory (possibly `.retrospective/` by luck, more likely `retrospectives/` or `docs/retrospectives/`)
- May create a template file, but it will be freeform and not match the 10-section structure
- Does not probe for available providers
- Does not create `.claude/retrospective.config.json`
- Does not ask the user about trigger mode (auto/prompt/manual)
- Does not ask about custom phase labels
- Does not detect phase definition type from available data
- May suggest a process in prose rather than creating actual infrastructure

**Specific failures:**
- No config file. The entire config schema (mode, providers, phase_definition, sections toggles, stakeholder_report settings, summary_tracker settings, hooks, pending_retro) is absent
- No provider probing step. The agent does not check `.planning/STATE.md`, `.git/`, or `gh auth status` to determine which providers are available
- No phase definition detection. The priority chain (GSD -> git tags -> GitHub milestones -> manual) is not followed
- Only 0-1 questions asked of the user (vs the skill's 2 required questions: trigger mode and custom label)
- Template created (if any) lacks: success criteria table, planned vs actual table, requirement completion table, confidence scores, edge cases section, forward-looking risks
- No stakeholder report template
- No SUMMARY.md template
- No hook configuration for post-phase-completion behavior
- No concept of `pending_retro` for deferred retrospectives

**Likely rationalizations:**
- "I've created a retrospective template you can use" (a generic template missing most structure)
- "You can customize this as needed" (avoiding the upfront configuration that makes customization unnecessary)
- "I've set up a basic structure that you can build on" (delivering less and framing it as flexibility)

---

## Summary of Gaps

The following are capabilities the skill enforces that agents naturally skip or fail to deliver:

1. **Structured 10-section template with tables** — Agents default to 3-5 sections of prose. The specific table structures (Success Criteria with Status/Evidence, Decisions with Options/Choice/Rationale, Issues with Severity/Resolution/Time Impact, Metrics with Planned/Actual/Delta) are never produced without explicit instruction.

2. **Provider probing and merging** — Agents use whatever data source is most obvious. They do not systematically probe for GSD, git, GitHub, and manual, nor merge data across providers with defined precedence.

3. **Manual gap-filling questions** — Agents ask 0-2 generic questions. The skill defines 7 specific gap-filling prompts for subjective context (surprises, what didn't go well, forward risks, stakeholder concerns). Without the skill, agents either skip these sections or fill them with platitudes.

4. **Config infrastructure** — The entire `.claude/retrospective.config.json` system (provider toggles, phase definitions, section toggles, trigger modes, pending retros, hooks) does not exist without the skill.

5. **Output directory and naming** — Agents write to project root or ad hoc locations. The `.retrospective/phase-<N>-<slug>.md` convention is not followed.

6. **Stakeholder report** — Never generated without explicit instruction. The separate plain-language, jargon-free report with readiness assessment for the next phase is a skill-only output.

7. **Cumulative SUMMARY.md** — Never created or updated. Cross-phase learnings, compounding risks, and the cumulative risk register require an ongoing tracking mechanism that agents do not spontaneously create.

8. **Honesty-first tone** — Agents default to diplomatic, positive-leaning tone. The skill's principle of surfacing "the bad and the ugly prominently" and treating sugarcoating as a failure mode is counter to default agent behavior. Confidence scores are either inflated or absent.

9. **Idempotency** — Without the skill's overwrite-on-rerun convention, agents create duplicate files or append.

10. **Hook and trigger behavior** — The prompt/auto/manual trigger modes and deferred retrospective reminders have no equivalent in default agent behavior.

## Recommendations for GREEN Phase

1. **Template adherence is the critical test.** The most visible failure in every scenario is structural: missing sections, prose instead of tables, absent confidence scores. The GREEN phase should verify all 10 sections are present with correct table formats.

2. **Manual question count is a proxy for thoroughness.** Count the gap-filling questions asked. Without the skill: 0-2. With the skill: 5-7 depending on available data. This is measurable.

3. **Test honesty with a failure-heavy scenario.** Scenario 4 is the most important. Verify that the retrospective leads with problems, uses severity ratings, quantifies time impact, and does not use softening language like "challenges" or "despite difficulties."

4. **Config round-trip test.** Run `/retro init` and verify the config file is written with correct provider detection. Then run `/retro` and verify it reads the config. This tests the infrastructure layer that has zero equivalent without the skill.

5. **Multi-provider merge test.** Scenario 2 is ideal. Verify that GSD data, GitHub PR data, and git stats all appear in the same retrospective, merged per the precedence rules rather than siloed.

6. **Stakeholder report and SUMMARY.md existence tests.** These are binary: they either exist or they don't. Without the skill, they don't.

7. **Consider adding a "completeness check" to the skill.** After generating, the skill could self-audit: count populated sections, verify tables have data rows, check that at least N manual questions were asked. This would catch partial implementations even when the skill is loaded.
