# Simplified Technical English: rule summary

A working summary of the writing rules in ASD-STE100, Issue 9 (January 2025), built from the public outline of the specification and a one-page seminar reference sheet. This file is unofficial and is not affiliated with or endorsed by ASD. When this summary and the specification disagree, the specification wins. Source: asd-ste100.org.

Contents: how the spec is organized; the nine rule sections; numeric limits; verb forms; general writing rules; safety instructions; the three dial levels; an annotated example.

## How the specification is organized

- Part 1, Writing rules: nine sections, numbered. Rule 5.1 belongs to Section 5, Procedures.
- Part 2, Dictionary: about 900 approved words, each with one part of speech and one meaning, plus unapproved words with their approved alternative. See `ste-dictionary.md`.
- Technical names and technical verbs: company-specific terms in defined categories (parts, tools, materials, locations, system states, operations on them). They are allowed on top of the dictionary. This is the escape hatch for domain terms, and it is why "declare it as a technical name" is the answer to most vocabulary conflicts.

History, for orientation: AECMA started the controlled-English work for airline maintenance in 1979, published the first Simplified English guide in 1986, and the spec became ASD-STE100 in 2005 after AECMA joined ASD. It is maintained by the Simplified Technical English Maintenance Group (STEMG) and is a free download. Originally aircraft maintenance; now also defence, rail, and general industry.

## The nine rule sections

Section 1, Words
- Use only approved words from the dictionary, technical names, and technical verbs.
- Use an approved word only in its listed part of speech and meaning. CLOSE is a verb; it never means "near".
- Use the same word for the same thing, every time. No elegant variation.

Section 2, Noun phrases (noun clusters)
- A noun phrase has at most three nouns ("brake unit assembly"); adjectives do not count. Some reference sheets, including the seminar sheet this summary draws on, say "3 words", which is the stricter reading.
- Longer clusters are split with prepositions or hyphens, or the cluster is declared a technical name.

Section 3, Verbs
- Use only the approved verb forms (table below).
- Use the active voice. Procedures are always active; descriptive text may use the passive only when it is necessary.
- Do not use the -ing form, except inside a technical name ("landing gear").
- Do not build complex tenses with helping verbs (no perfect, no "would have").

Section 4, Sentences
- Keep sentences short. One topic per sentence.
- Do not drop words to hit the count. Keep "the", "a", "this", and the verb.
- Use a vertical list when a sentence has more than one instruction or a long series of items.
- Use connecting words (then, but, because) at the start of a sentence to link it to the one before.

Section 5, Procedures
- At most 20 words per sentence.
- One instruction per sentence, unless two actions happen at the same time ("Hold the lever and push the button").
- Write instructions as commands (the imperative form).
- Put the condition before the instruction it governs ("If the light is on, stop the pump").

Section 6, Descriptive writing
- At most 25 words per sentence.
- At most 6 sentences per paragraph; one topic per paragraph.
- Start the paragraph with the sentence that carries the topic.

Section 7, Safety instructions
- WARNING means risk of injury or death. CAUTION means risk of damage to equipment. A note is for information only and never carries a risk.
- Start with a clear, simple command (or a condition and then a command). Then state the risk.
- Put the warning or caution before the step it applies to, not inside it or after it.

Section 8, Punctuation and word counts
- Count words in every sentence; the limits are hard.
- Use a colon or dash to introduce a vertical list; the items are counted as their own sentences.
- Use hyphens to make a noun cluster readable ("fuel-tank cover").
- Use parentheses only for cross-references and very short clarifications.

Section 9, Writing practices
- Plan before you write: know who the reader is and what task they are doing.
- Use tables, illustrations, and lists where they say it better than prose.
- Check the finished text against the dictionary and the limits, then check it again for meaning.

## Numeric limits

| Item | Maximum |
|------|---------|
| Procedural sentence | 20 words |
| Descriptive sentence | 25 words |
| Descriptive paragraph | 6 sentences |
| Noun phrase (noun cluster) | 3 nouns; adjectives do not count (the seminar sheet says 3 words) |
| Instructions in one sentence | 1, except actions done at the same time |

## Verb forms (Section 3)

| Form | Example | Status |
|------|---------|--------|
| Command (imperative) | Close the valve. | approved |
| Simple present | The valve closes. | approved |
| Simple past | The valve closed. | approved |
| Simple future | The valve will close. | approved |
| Infinitive | Turn the knob to close it. | approved |
| Past participle as adjective | the closed valve | approved |
| Progressive (-ing) | The valve is closing. | not approved |
| Perfect | The valve has closed. | not approved |
| Passive, in procedures | The valve must be closed. | not approved |

## General writing rules

- Use the same word for the same thing every time.
- Do not leave out words like "the", "a", and "this".
- Use the active voice in procedures.
- Use vertical lists for complex text.
- Write one topic in each paragraph.

## Safety instruction format

```
WARNING: Do not touch the brake unit until it is cool. Hot parts can cause injury.
          ^ first, a clear simple command              ^ then, the risk
```

WARNING for injury, CAUTION for damage. Command first, risk second. Never bury the command after the explanation.

## The dial: strict, 80, light

| | strict | 80 | light (default) |
|---|---|---|---|
| Sentence length | 20 words procedural, 25 descriptive, hard | hard cap 25 words | about 15 words average, no hard cap |
| Paragraphs | max 6 sentences, one topic | max 6 sentences, one topic | one idea per sentence; paragraphs free |
| Verb forms | approved forms only | approved forms; "is/are" plus -ing allowed when it reads naturally | free |
| Voice | active | active | free |
| Vocabulary | approved words only; domain terms only when declared as technical names or technical verbs on first use | substitution table applied; domain nouns are free and need no declaration | plain-verb substitutions from the table (ensure, utilize, prior to, in order to, and similar); everything else free |
| Instructions per sentence | one, except simultaneous actions | one preferred | free |
| Semicolons, contractions, Latin abbreviations (e.g., i.e., etc.) | none | allowed sparingly | free |
| Consistent terms | required | required | encouraged |
| Source facts, numbers, caveats, hedges | all kept | all kept | all kept |

The last row is the one that never moves, and at every level a domain term is kept as written, never swapped for a near-synonym. See the guardrails in SKILL.md. This table is the single definition of the three levels; SKILL.md points here rather than restating it.

## Annotated example

Original, not STE (unapproved words marked):

> It is *imperative* that the operator *ensures* the hydraulic reservoir is *replenished prior to commencing* operation.

Procedural rewrite, 13 words against a limit of 20:

> Make sure that the hydraulic reservoir is full before you start the operation.

- "Make sure": approved verb, command form (replaces "ensure", "imperative").
- "hydraulic reservoir": technical name, two-word noun cluster (limit 3).
- "is full": replaces "is replenished"; "replenish" is not approved, FILL is.
- "before": replaces "prior to".
- "you start": active voice; "start" replaces "commencing", and the -ing form is gone.

Descriptive sentence, 12 words against a limit of 25:

> The pump supplies fuel to the engine when the switch is on.

Simple present tense, one topic, active voice.
