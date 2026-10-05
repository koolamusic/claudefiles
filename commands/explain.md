---
name: explain
allowed-tools: Read, Bash(python3:*), Bash(bash:*), Bash(uv:*), Bash(ffmpeg:*)
description: Explain a topic as Simplified Technical English prose, a diagram, an HTML page, or a video, with a strictness dial
---

## Context

Front door for the `explainer-formats` skill. Usage:

```
/explain <topic> [--as ste|diagram|html|video] [--level strict|80|light]
```

Defaults are `--as ste` and `--level light`. The topic can be a question, a pasted paragraph, a file path, or a symbol name.

## Your task

1. Load the `explainer-formats` skill and follow it.
2. Parse `$ARGUMENTS`: everything before the first `--as` or `--level` flag is `<topic>`; the flags set the rung and the level. A missing flag takes the default. An unknown rung or level is an error; say which values are valid and stop.
3. Hand the skill `<topic> --as <rung> --level <level>` and return its output, including the closing line that offers the next rung.
