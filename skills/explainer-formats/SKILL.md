---
name: explainer-formats
description: Use when asked to explain a topic, codebase, process, or document in a specific output format — plain language or Simplified Technical English (STE, in the style of ASD-STE100 with its controlled vocabulary and short procedural sentences), a diagram, a standalone HTML page, or a narrated video explainer. Triggers on "explain", "explainer", "simplified technical english", "STE", "plain language", "rewrite this so a technician can follow it", "diagram", "html page", "video explainer", or the /explain command. Picks the lowest format that answers the question and offers the next one.
---

# Explainer formats

One command, four output formats (rungs), ordered from cheapest to most expensive:

| Rung | Output | Reference to load | Status |
|------|--------|-------------------|--------|
| `ste` | Prose rewritten in Simplified Technical English at a chosen strictness | `references/ste-rules.md`; `references/ste-dictionary.md` at strict (and for substitutions at 80%) | ready |
| `diagram` | A diagram of the mechanism, with STE captions | `references/diagram.md` | Phase 2, not yet written |
| `html` | A standalone HTML explainer page | `references/html.md` | Phase 2, not yet written |
| `video` | A narrated video built from the HTML or diagram | `references/video.md` and `scripts/` pipeline | Phase 3, not yet written |

If a rung's reference file does not exist yet, say so in one line and fall back to `ste`.

## Invocation

```
/explain <topic> [--as ste|diagram|html|video] [--level strict|80|light]
```

Defaults: `--as ste`, `--level light`. `<topic>` is anything the reader points at: a question, a pasted paragraph, a file path, a function name, a feature. When the topic is a file or symbol, read it first and explain what is there, not what it is named.

## Escalation rule

Pick the lowest rung that answers the question. A question about what something does is answered in prose. A question about how parts connect or flow is where a diagram starts to pay for itself. A page or video is only worth it when the explanation has to live on its own, away from this conversation, or when the reader asked for it.

Always end the answer with one line that offers the next rung up, for example:

> Want this as a diagram? `/explain <topic> --as diagram`

Never escalate silently. If the reader asked for `--as html` and prose would have done, still deliver the page and say so in that closing line.

## Guardrails that apply at every level

These are not optional and they do not relax at `light`. A rewrite that reads well but drops a fact is a failure.

- Keep every fact, number, unit, caveat, condition, and domain term from the source. Hedges in the source ("usually", "unless the cache is cold") are facts; keep them.
- Never invent. If the source does not say why, the rewrite does not say why. If something is unclear, say it is unclear rather than guessing.
- Leave code, commands, flags, file paths, identifiers, error messages, and quoted output exactly as written. Do not rewrite them into prose, change their case, or "simplify" them.
- A domain term that is not an approved word stays in the text. Declare it as a technical name on first use ("the hydraulic reservoir, a technical name for the tank that holds the fluid") and then use it unchanged. Do not swap it for a near-synonym.
- One source of truth: when a fact appears twice in the source with different numbers, keep both and flag the conflict. Do not pick one.

Why this is strict: a published test of a prompt that said only "write this in ASD-STE100" lost 47% of the code-specific facts in the source. The vocabulary rules pulled the model toward fluent sentences and away from the content. The guardrails above and the `light` default exist to prevent that.

## The `ste` rung

1. Read `references/ste-rules.md`. It has the nine rule sections, the numeric limits, the verb forms table, the safety instruction format, and the three-level dial.
2. Apply the level:
   - `light` (default): short sentences, one idea each, plain-verb substitutions. Reads like a careful technical writer, not like a specification.
   - `80`: the word and paragraph limits, active voice, approved verb forms, the substitution table. Domain nouns are free.
   - `strict`: everything in the specification. Load `references/ste-dictionary.md` and use approved vocabulary only; undeclared domain terms are an error.
3. At `80` and `strict`, consult the substitution table in `references/ste-dictionary.md` for every verb and connector you are unsure about. At `light`, use the table from memory for the common swaps (ensure, utilize, prior to, in order to) and do not load the file.
4. Run the guardrails above as a checklist against the source before answering. Count the facts in the source; count them in the output.
5. For `strict` output, optionally lint with the bundled checker:

   ```
   python3 scripts/ste_check.py output.txt        # or: cat output.txt | python3 scripts/ste_check.py
   ```

   It wraps the open-source `ste100-checker` through `uvx` and prints JSON findings. Treat its findings as hints; the dictionary in `references/` is the authority when they disagree.

Output format for `ste`: the rewritten text, then a short line naming the level used and any technical names declared, then the escalation line.

## Machine check

`bash scripts/doctor.sh` prints what the later rungs need on this machine (Python, uv, ffmpeg, manim, kokoro-onnx, espeak-ng, an ElevenLabs key by name only) and writes `machine.toml` in the skill root. Read-only; it installs nothing. Run it before attempting `video` once Phase 3 lands.

## Not affiliated

The STE references summarize the public outline of ASD-STE100 Issue 9 (January 2025) and a seminar reference sheet. This skill is unofficial and is not affiliated with or endorsed by ASD. The dictionary bundled here is partial; the full Issue 9 word list is held under the maintainer's company licence and is added separately.
