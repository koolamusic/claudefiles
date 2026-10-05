# The video rung

Load this file when `/explain` runs with `--as video`. A video is the most expensive rung: it needs a per-machine setup, a narration backend, and a render loop. Build one only when the reader asked for it or when an html page would still leave the sequence of events unclear. The guardrails in SKILL.md apply to the narration word for word.

Contents: the pipeline; the beats script; Manim scene rules; the render-fix loop; choosing the narration backend; delivery; what the reply must state.

## The pipeline

All Python runs in the uv project under `scripts/` on Python 3.12 (the system 3.14 breaks kokoro-onnx). Nothing needs activating; every call is `uv run --project scripts python scripts/<file>.py`.

```
bash scripts/doctor.sh                                   # what is present; writes machine.toml
bash scripts/setup.sh [--latex]                          # the only step that installs anything
uv run --project scripts python scripts/tts.py beats.md --out work/beats [--backend kokoro|elevenlabs|espeak]
uv run --project scripts python scripts/render.py scenes.py work/beats --out work/video --quality draft --only 1
uv run --project scripts python scripts/render.py scenes.py work/beats --out work/video --quality final [--target-mb 15]
```

`tts.py` writes one `beat_NN.wav` (24 kHz mono) per beat and `durations.json`. `render.py` renders one Manim scene per beat, muxes each with its narration (`-shortest`, `+faststart`), concatenates them into `final.mp4`, and prints the length, the size, and whether it fits the two artifact caps. Work files go in a scratch directory, never in the skill.

## The beats script

Markdown. One `## Beat N` heading per beat, the narration paragraph under it at the current STE level (`light` by default), and optional `visual:` lines that describe what the scene shows; `tts.py` skips those lines. Keep a beat to one idea and 15 to 40 words; a long beat makes a long static scene.

```markdown
## Beat 1
visual: three commits in a row, each box shows a short hash
A commit hash covers the commit's content and the hash of its parent. Change the parent, and the hash changes.

## Beat 2
visual: the three commits lift off the old base and land on a new one
A rebase moves your commits onto a new base. Each commit gets a new parent, so each one gets a new hash.

## Beat 3
visual: the old chain fades but stays on screen, labelled "reflog"
The old commits are not deleted at once. They stay in the reflog until Git prunes them.
```

## Manim scene rules

`scenes.py` holds one `Scene` subclass per beat, named `Beat01`, `Beat02`, and so on, in beat order.

- The scene's total time (animation run times plus `self.wait()`) equals that beat's seconds from `durations.json`. `render.py` passes the beats directory in `EXPLAINER_BEATS_DIR`; read it with the helper below and spend the remainder in a final `self.wait()`. A scene shorter than its narration is cut off by `-shortest`; `render.py` warns when that would happen.
- Use `Text`, not `MathTex` or `Tex`, unless `doctor.sh` shows `latex` present. `Text` renders through Pango and needs no LaTeX.
- Keep every mobject inside the frame: the default frame is 14.2 by 8 units; scale groups with `.scale_to_fit_width(12)` when in doubt.
- The 3b1b conventions: dark background (the default), one idea on screen at a time, animate the change rather than cutting to the new state (`Transform`, `FadeIn`, `.animate.shift`), and leave the last state on screen through the final wait.
- Labels inside the scene follow the STE word choices, like diagram labels. Identifiers stay exact, in a monospace font (`Text("git rebase", font="monospace")`).

Helper to put at the top of `scenes.py`:

```python
import json, os
from pathlib import Path
from manim import *

def beat_seconds(n):
    d = Path(os.environ.get("EXPLAINER_BEATS_DIR", "work/beats")) / "durations.json"
    return json.loads(d.read_text()).get(str(n), 5.0)

class Beat01(Scene):
    def construct(self):
        t0 = beat_seconds(1)
        title = Text("A commit hash covers its parent", font_size=40)
        self.play(Write(title), run_time=2)
        self.wait(max(t0 - 2, 0.5))
```

## The render-fix loop

1. Draft one beat: `render.py ... --quality draft --only N`. Draft is `-ql` (480p, 15 fps) and renders in seconds.
2. If Manim fails, the error and the scene name are printed. Fix that one scene in `scenes.py`; do not touch the others. Repeat.
3. Watch the duration warning. If the scene is shorter than its narration, add to the final `self.wait()`.
4. Only when every beat drafts clean, render all beats at `--quality final` (`-qh`, 1080p, 60 fps). A final render of a two-minute video takes minutes, so do not use it to find errors.
5. If the size report says the file is over a cap, re-run with `--target-mb 15`; it re-encodes at a computed bitrate.

## Choosing the narration backend

Pick once per session and say which in the reply.

| Backend | Pick it when | Needs |
|---|---|---|
| `kokoro` (default) | normal use: good voice, offline, free | the model files from `setup.sh` (about 340 MB, once) |
| `elevenlabs` | the reader wants a specific premium voice | `ELEVENLABS_API_KEY` (and optional `ELEVENLABS_VOICE_ID`) in the environment or the raydr env file; the `elevenlabs` extra |
| `espeak` | nothing else is available, or a fast check of timings | the `espeak-ng` system package |

`--voice` selects the kokoro voice (`af_heart` default), the ElevenLabs voice id, or the espeak voice. `--speed` applies to kokoro and espeak. Key values are read, never printed; `doctor.sh` reports only the key's name.

## Delivery

- Under the caps (final.mp4 under 15 MB): publish a player page as an artifact. The page is a short HTML document with a `<video controls>` tag; declare the `assets` capability (load `artifact-capabilities` first), publish the page, then `upload_asset` the mp4 to it and set the `<video>` source to the returned url. Load `artifact-design` before writing the page, as the html rung requires.
- Over the caps: use the `publish-page` skill, which serves the file behind a local proxy for 24 or 48 hours. Or re-encode with `--target-mb` first if the quality loss is acceptable.
- A file on disk only when the reader asked for the file; say where it is.

## What the reply must state

The backend used, the file length and size in MB from the `render.py` report, which cap it fits, the route taken (artifact player page or `publish-page`) and its link, the STE level of the narration, and the path to `beats.md` so the narration can be edited and re-run. Video is the top rung; the closing line offers an edit, not a next format.
