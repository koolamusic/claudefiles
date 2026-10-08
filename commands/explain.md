---
name: explain
allowed-tools: Read, Bash(python3:*), Bash(bash:*), Bash(uv:*), Bash(ffmpeg:*), Bash(node:*)
description: Explain a topic as Simplified Technical English prose, a diagram, an HTML page, or a video, with a strictness dial
---

## Context

Front door for the `explainer-formats` skill. Usage:

```
/explain <topic> [--as <format>] [--level strict|80|light]
/explain <topic> as <format>
/explain formats
```

Defaults are `--as ste` and `--level light`. The topic can be a question, a pasted paragraph, a file path, or a symbol name. `<format>` is a rung (`ste`, `diagram`, `html`, `video`) or any visualizer diagram type (`architecture`, `sequence`, `sankey`, ...); the full list is `references/formats.md` in the skill.

## Your task

1. Load the `explainer-formats` skill and follow it.
2. If `$ARGUMENTS` is exactly `formats` (or empty apart from that word), print the skill's `references/formats.md` and stop.
3. Otherwise parse `$ARGUMENTS`: everything before the first `--as` or `--level` flag is `<topic>`; the flags set the format and the level. With no `--as`, a trailing `as <format>` (the last `as` followed by one word) sets the format and is removed from the topic. A missing flag takes the default. A format that is neither a rung nor a visualizer type, or an unknown level, is an error; say which values are valid and stop.
4. Hand the skill `<topic> --as <format> --level <level>` and return its output, including the closing line that offers the next rung.
