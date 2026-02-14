---
name: skill-creator
description: Guide for creating effective skills. Use when creating a new skill, updating an existing skill, or verifying skills work before deployment. Covers skill structure, creation process, testing methodology, and packaging.
---

# Skill Creator

Create effective, tested skills that extend Claude's capabilities with specialized knowledge, workflows, and tools.

## About Skills

Skills are modular packages that provide:
1. **Specialized workflows** - Multi-step procedures for specific domains
2. **Tool integrations** - Instructions for working with specific file formats or APIs
3. **Domain expertise** - Company-specific knowledge, schemas, business logic
4. **Bundled resources** - Scripts, references, and assets for complex tasks

## Core Principles

### Concise is Key

The context window is a public good. Only add context Claude doesn't already have. Challenge each piece: "Does Claude really need this?" Prefer concise examples over verbose explanations.

### Set Appropriate Degrees of Freedom

- **High freedom** (text instructions): Multiple approaches valid, context-dependent
- **Medium freedom** (pseudocode/parameterized scripts): Preferred pattern exists, some variation OK
- **Low freedom** (specific scripts): Fragile operations, consistency critical

### Progressive Disclosure

Three-level loading to manage context efficiently:
1. **Metadata** (name + description) - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<5k words, under 500 lines)
3. **Bundled resources** - As needed (unlimited, loaded on demand)

## Skill Anatomy

```
skill-name/
├── SKILL.md              # Required: frontmatter + instructions
├── scripts/              # Optional: executable code (Python/Bash)
├── references/           # Optional: docs loaded into context as needed
└── assets/               # Optional: files used in output (templates, icons)
```

### SKILL.md Frontmatter

Only `name` and `description` are required. The description is the primary trigger — it determines when the skill loads.

```yaml
---
name: my-skill
description: Use when [specific triggering conditions and symptoms]
---
```

**Description rules:**
- Start with "Use when..." — focus on triggering conditions
- Include specific symptoms, situations, and contexts
- Write in third person
- **NEVER summarize the skill's workflow** in the description (Claude may follow the summary instead of reading the full skill)

### Bundled Resources

- **scripts/**: Deterministic, reusable code. Token-efficient. Test by running them.
- **references/**: Documentation Claude reads as needed. Keep SKILL.md lean by moving detailed info here. For large files (>10k words), include grep patterns in SKILL.md.
- **assets/**: Files for output (templates, images, fonts). Not loaded into context.

**Do NOT include:** README.md, CHANGELOG.md, INSTALLATION_GUIDE.md, or auxiliary docs about the creation process.

## Creation Process

### Step 1: Understand with Concrete Examples

Ask the user:
- What should the skill support?
- Example usage scenarios?
- What triggers should activate this skill?

### Step 2: Plan Reusable Contents

For each example, identify what scripts, references, and assets would help when executing these workflows repeatedly.

### Step 3: Initialize the Skill

Create the skill directory with a SKILL.md containing frontmatter (name + description) and the appropriate resource subdirectories (scripts/, references/, assets/) as needed.

### Step 4: Edit the Skill

Consult these guides based on your needs:
- **Multi-step processes**: See references/workflows.md
- **Output formats/quality standards**: See references/output-patterns.md
- **Official authoring guidance**: See references/anthropic-best-practices.md

Start with reusable resources, then write SKILL.md. Use imperative/infinitive form.

### Step 5: Validate & Package

Verify the skill has valid frontmatter (name + description, kebab-case name, under 1024 chars), then package with `zip -r skill-name.skill skill-name/` if distributing.

### Step 6: Iterate with TDD

**Skill creation IS Test-Driven Development applied to process documentation.**

Follow RED-GREEN-REFACTOR:

**RED — Baseline test (before writing/editing the skill):**
1. Create pressure scenarios (3+ combined pressures for discipline skills)
2. Run scenarios with a subagent WITHOUT the skill
3. Document exact behavior: choices, rationalizations (verbatim), failures

**GREEN — Write minimal skill:**
1. Address the specific rationalizations observed in RED
2. Don't add content for hypothetical cases
3. Run same scenarios WITH skill — agent should now comply

**REFACTOR — Close loopholes:**
1. Identify new rationalizations from testing
2. Add explicit counters for each
3. Build rationalization table, red flags list
4. Re-test until bulletproof

**The Iron Law: No skill without a failing test first.** This applies to new skills AND edits.

For the complete testing methodology (pressure scenarios, pressure types, plugging holes, meta-testing), see references/testing-skills-with-subagents.md.

For psychology of persuasion techniques in discipline-enforcing skills, see references/persuasion-principles.md.

## Claude Search Optimization (CSO)

Future Claude needs to FIND your skill:

1. **Rich description** — "Use when..." with concrete triggers and symptoms
2. **Keyword coverage** — Error messages, symptoms, synonyms, tool names
3. **Descriptive naming** — Verb-first, active voice (`condition-based-waiting` not `async-test-helpers`)
4. **Token efficiency** — Frequently-loaded skills <200 words; move details to references

## Skill Types & Testing

| Type | Examples | Test With |
|------|----------|-----------|
| **Discipline** (rules) | TDD, verification | Pressure scenarios, rationalization resistance |
| **Technique** (how-to) | condition-based-waiting | Application + edge cases |
| **Pattern** (mental model) | flatten-with-flags | Recognition + counter-examples |
| **Reference** (docs/APIs) | API guides | Retrieval + application accuracy |

## Progressive Disclosure Patterns

**Pattern 1:** High-level guide linking to references for advanced features
**Pattern 2:** Domain-specific organization (only load relevant domain file)
**Pattern 3:** Conditional details (basic inline, advanced linked)

Keep references one level deep from SKILL.md. For files >100 lines, include a table of contents.

## Common Mistakes

- Descriptions that summarize workflow (Claude takes shortcut, skips body)
- Narrative storytelling instead of reusable patterns
- Multi-language dilution (one excellent example beats many mediocre ones)
- Code in flowcharts (can't copy-paste)
- Deeply nested references (keep one level deep)
- Skipping testing ("obviously clear" to you != clear to agents)

## Flowcharts

Use ONLY for non-obvious decisions, process loops, or A-vs-B choices. Never for reference material, code examples, or linear instructions.
