# The html rung

Load this file when `/explain` runs with `--as html`, or when the escalation rule says a diagram is not enough. The guardrails in SKILL.md still apply on the page: every fact, number, and caveat from the source is on it, code is untouched, nothing is invented.

Contents: when a page is the right rung; skills to load; diagrams inside the page; publishing and its limits; page content rules; the skeleton outline; delivery.

## When a page is the right rung

Build a page when the explanation gains from at least one of:

- interaction: a toggle between two states, a step-through of a procedure, a slider over a parameter, tabs for alternative paths;
- layout: a side-by-side comparison that prose would force into "on the one hand, on the other hand";
- persistence: the reader wants to keep it, share it with someone who was not in the conversation, or come back to it.

If none of the three applies, the diagram rung (or prose) is the answer, and the page is a cost. When the reader asked for a page anyway, build it and say in the closing line that prose would have done.

## Skills to load before writing

These are built into Claude Code; invoke them by name.

- `artifact-design`, always, before the first line of the page. It sets the design effort, the theme tokens, phone width, and the publishing skeleton.
- `artifact-capabilities`, only when the page needs state that survives a reload, viewer identity, data shared between viewers, or a call to Claude from the page. A static explainer does not need it; do not declare capabilities it will not use.
- `dataviz` if any element on the page is a chart, stat tile, or dashboard.

## Diagrams inside the page

Use Mermaid fences (```mermaid or `<pre class="mermaid">`) for flow, sequence, and state diagrams; the artifact viewer renders them with no library. Use inline SVG for callouts and theme-sensitive figures, following `diagram.md` and `artifact-diagramming`. Every diagram on the page carries its STE caption directly under it.

## Publishing

Default: the Artifact tool. The page gets a private URL on claude.ai, renders in the viewer's theme, and works at phone width. Share by sending the link; the reader decides who else sees it.

Use the `publish-page` skill instead when a public URL is needed with no claude.ai account on the reader's side, or when the page carries a file over the artifact caps below. It serves the page behind a local proxy and tears it down after 24 or 48 hours.

Artifact caps to respect: the rendered page 16 MB (embedded data URIs included); a binary supporting file 15 MB; an uploaded asset 20 MiB. Over any of those, split the page, link to the file instead of embedding it, or use `publish-page`.

The Artifact tool's sandbox allows external scripts and stylesheets only from a short list of hosts (the Artifact tool's description names them); everything else is inlined. Do not promise a download link from inside an artifact; the sandbox blocks page-initiated downloads.

## Page content rules

- Prose on the page is written at the current STE level (`light` by default; see `ste-rules.md`). The level does not change between sections.
- Headings are short noun phrases: "Reservoir check", not "How to check the reservoir before starting".
- One idea per section. A section that needs "also" is two sections.
- Code, commands, file paths, and identifiers are untouched, in code blocks or inline code, never paraphrased into prose.
- Numbers and caveats from the source appear where the reader needs them, not collected into a footnote.
- An interactive element must still make sense with the interaction removed: the toggle's two states are both readable as text; the step-through's steps are a numbered list when scripting is off.

## Skeleton outline

Not a full HTML file; a shape to fill. The `<title>` is two to four words naming the subject, not a summary.

```
<title>            two to four words, the subject
Summary            one sentence at the STE level: what this page explains and for whom
Sections           three to six, each a short noun-phrase heading
                   - the mechanism (prose, then a Mermaid or SVG figure with caption)
                   - the procedure or flow (a numbered list, or the step-through if interactive)
                   - the comparison, if the page exists for one (side-by-side, readable stacked on a phone)
                   - the limits: numbers, thresholds, caveats, pulled from the source
What to read next  two to four links or references the source names; nothing invented
```

Each section opens with its one idea in a sentence, then the figure or list, then the number or caveat that applies. No section header is a question.

## Delivery

In the reply: the artifact link (or the `publish-page` URL), one line saying which STE level the prose uses, then the escalation line from SKILL.md. The video rung is the next step up; offer it only once it is available, otherwise close with the page.
