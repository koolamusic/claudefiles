---
name: explainer-formats
description: Use when asked to explain a topic, codebase, process, or document in a specific output format — plain language or Simplified Technical English (STE, in the style of ASD-STE100 with its controlled vocabulary and short procedural sentences), a diagram, a standalone HTML page, or a narrated video explainer. Triggers on "explain", "explainer", "simplified technical english", "STE", "plain language", "rewrite this so a technician can follow it", "diagram", "html page", "video explainer", or the /explain command. Picks the lowest format that answers the question and offers the next one.
---

# Explainer formats

One command, four output formats (rungs), ordered from cheapest to most expensive:

| Rung | Output | Reference to load | Status |
|------|--------|-------------------|--------|
| `ste` | Prose rewritten in Simplified Technical English at a chosen strictness | `references/ste-rules.md`; `references/ste-dictionary.md` at strict (and for substitutions at 80%) | ready |
| `diagram` | A Mermaid or SVG diagram of the mechanism, with an STE caption | `references/diagram.md` | ready |
| `html` | A standalone explainer page, published as an artifact or a public page | `references/html.md` | ready |
| `video` | A narrated Manim video, one scene per beat, published as an artifact player page | `references/video.md`; `scripts/` pipeline run as `uv run --project scripts python scripts/<file>.py` | ready |

If a rung's reference file does not exist yet, say so in one line and fall back to the highest rung below it that is ready.

## Invocation

```
/explain <topic> [--as ste|diagram|html|video] [--level strict|80|light]
```

`/explain` is the `explain` command in `~/.claude/commands/`; it loads this skill and passes its arguments through. Defaults: `--as ste`, `--level light`. `<topic>` is anything the reader points at: a question, a pasted paragraph, a file path, a function name, a feature. When the topic is a file or symbol, read it first and explain what is there, not what it is named.

## Escalation rule

Pick the lowest rung that answers the question. A question about what something does is answered in prose (`ste`). A question about how parts connect, flow, or change state, where prose would run past two paragraphs, is where a diagram starts to pay for itself (`diagram`). A page is worth it when the explanation gains from interaction or side-by-side layout, or when the reader wants to keep it or share it outside this conversation (`html`). A video is the step above a page: build one only when the reader asked for it, or when a page would still leave the order of events unclear.

Always end the answer with one line that offers the next rung up, for example:

> Want this as a diagram? `/explain <topic> --as diagram`

From `ste` offer `diagram`; from `diagram` offer `html`; from `html` offer `video`; from `video` offer an edit to the narration, since there is no rung above it.

Never escalate silently. If the reader asked for `--as html` and prose would have done, still deliver the page and say so in that closing line.

## Guardrails that apply at every level

These are not optional and they do not relax at `light`. A rewrite that reads well but drops a fact is a failure.

- Keep every fact, number, unit, caveat, condition, and domain term from the source. Hedges in the source ("usually", "unless the cache is cold") are facts; keep them.
- Never invent. If the source does not say why, the rewrite does not say why. If something is unclear, say it is unclear rather than guessing.
- Leave code, commands, flags, file paths, identifiers, error messages, and quoted output exactly as written. Do not rewrite them into prose, change their case, or "simplify" them.
- A domain term that is not an approved word stays in the text as written. Never swap it for a near-synonym. (At `strict` only, also declare it as a technical name on first use; see the rung below.)
- One source of truth: when a fact appears twice in the source with different numbers, keep both and flag the conflict. Do not pick one.

Why this is strict: a published test of a prompt that said only "write this in ASD-STE100" lost 47% of the code-specific facts in the source (allaboutcoding.ghinda.com/explain-to-me-in-simple-technical-english). The vocabulary rules pulled the model toward fluent sentences and away from the content. The guardrails above and the `light` default exist to prevent that.

## The `ste` rung

1. Read `references/ste-rules.md`. It has the nine rule sections, the numeric limits, the verb forms table, the safety instruction format, and the dial table. The dial table is the single definition of what `strict`, `80`, and `light` allow; do not work from memory of it.
2. Apply the level from the dial table. In one line each: `light` (default) reads like a careful technical writer, not a specification; `80` applies the limits, active voice, and the substitution table while domain nouns stay free and undeclared; `strict` is everything in the specification, with every domain term declared as a technical name on first use ("the hydraulic reservoir, a technical name for the tank that holds the fluid").
3. Vocabulary authority: if `references/ste-dictionary-full.md` exists, use it as the authority. Otherwise use `references/ste-dictionary.md`, which is partial. Load it at `strict`; at `80` consult its substitution table for every verb and connector you are unsure about; at `light` use the common swaps from memory (ensure, utilize, prior to, in order to) and do not load the file.
4. Run the guardrails above as a checklist against the source before answering. Count the facts in the source; count them in the output.
5. For `strict` output, optionally lint with the bundled checker:

   ```
   python3 scripts/ste_check.py output.txt        # or: cat output.txt | python3 scripts/ste_check.py
   ```

   It wraps the open-source `ste100-checker` through `uvx` and prints JSON findings. Treat its findings as hints; the dictionary in `references/` is the authority when they disagree.

Output format for `ste`: the rewritten text, then a short line naming the level used and any technical names declared, then the escalation line.

## Machine check

`bash scripts/doctor.sh` prints what the video rung needs on this machine (Python, uv and its 3.12, ffmpeg, manim, kokoro-onnx and its model files, espeak-ng, LaTeX, an ElevenLabs key by name only). It installs nothing; it writes only `machine.toml` (gitignored) in the skill root. `bash scripts/setup.sh` is the one script that installs; run doctor first, then setup, before the first `video`.

## Not affiliated

The STE references summarize the public outline of ASD-STE100 Issue 9 (January 2025) and a seminar reference sheet. This skill is unofficial and is not affiliated with or endorsed by ASD. ASD-STE100 is free of charge but copyright ASD; the bundled dictionary is partial and the full word list is not redistributed here.
