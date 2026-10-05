# The diagram rung

Load this file when `/explain` runs with `--as diagram`, or when the escalation rule says prose is not enough. The guardrails in SKILL.md still apply: every fact in the source survives, and nothing is invented to make the picture tidy.

Contents: when a diagram is the right rung; choosing Mermaid, SVG, or an image file; skills to load before drawing; narration and labels; a worked Mermaid example; an SVG callout snippet; delivery.

## When a diagram is the right rung

Draw when the thing to explain is a mechanism, a flow, a hierarchy, a timeline, or a state machine, and prose would take more than two paragraphs to convey it. Those shapes have parts and connections; a reader holds a picture of them more easily than a list of sentences.

Do not draw when the question is "what does this do" (prose answers it), when the source has fewer than three moving parts, or when the diagram would only decorate an answer that is already clear. A diagram that restates one sentence is a cost, not a help.

## Choosing the form

| Form | Use it for | Why |
|------|-----------|-----|
| Mermaid | flowcharts, sequence, state, class, ER, Gantt, timelines | Renders natively in Claude artifacts from a ```mermaid fence; no library, no layout work. Also readable as text in the terminal. |
| Inline SVG | precise layout, annotation callouts, a figure that must read in both light and dark themes | Full control of position, color tokens, and callout lines. |
| Image file (PNG, SVG file) | only when the user asks for a file | Loses editability and theme handling; the user has to want it. |

Default to Mermaid. Move to SVG only when Mermaid cannot place a callout where it is needed, when two parts must sit at exact positions, or when the figure is going into a page that has to work in both themes.

## Skills to load before drawing

These are built into Claude Code, not files on disk; invoke them by name.

- `artifact-diagramming` before any inline SVG: it has the mechanics that keep SVG legible in both themes (currentColor, token fills, font fallbacks) and the judgement on whether the picture shows the real mechanism.
- `dataviz` whenever the picture is a chart, plot, stat tile, meter, or dashboard, even a small one. A bar of numbers is a chart, not a diagram, and it has its own rules.

Mermaid alone needs neither; write the fence directly.

## Narration and labels

Every diagram ships with a caption of one to three sentences at the current STE level (`light` by default; see `ste-rules.md`). The caption says what the reader is looking at and what the one important path or state is. It does not repeat every label.

Labels inside the diagram follow the STE word choices: approved verbs in the command form ("Start the pump", not "Pump initiation"), no Latinate nouns ("check", not "verification"), one noun phrase per node, three nouns at most. Code, command names, and identifiers stay exact. In Mermaid write them plain, with no backticks: Mermaid renders backticks inside labels as literal characters. In SVG or HTML put them in a monospace `tspan` or `<code>`.

Keep the diagram to what the source says. If the source does not state an order, do not draw an arrow that implies one.

## Worked example: a procedure as a Mermaid flowchart

Source procedure: "Before you start the pump, make sure that the reservoir is full. If it is not full, fill it. Then set the switch to ON and do a check of the pressure gauge. If the pressure is below 30 bar, stop the pump and tell the supervisor."

```mermaid
flowchart TD
    A[Make sure that the reservoir is full] -->|full| C[Set the switch to ON]
    A -->|not full| B[Fill the reservoir]
    B --> C
    C --> D[Do a check of the pressure gauge]
    D -->|30 bar or more| E([End of the stated procedure])
    D -->|below 30 bar| F[Stop the pump]
    F --> G[Tell the supervisor]
```

Caption (light): The procedure starts with a check of the reservoir and ends in one of two places. If the gauge shows less than 30 bar after you start, stop the pump and tell the supervisor.

Everything in the chart is in the source: the two conditions, the 30 bar threshold, the stop-and-tell branch. The source does not say what to do at 30 bar or above, so the chart ends that branch with an end marker rather than inventing a step.

## SVG callout snippet

A callout points at one part of a figure and names it. The shapes use `currentColor` so they follow the page's text color in either theme; load `artifact-diagramming` for the full pattern.

```html
<svg viewBox="0 0 320 120" width="320" role="img" aria-label="Pressure gauge with callout">
  <circle cx="70" cy="60" r="40" fill="none" stroke="currentColor" stroke-width="2"/>
  <line x1="70" y1="60" x2="95" y2="35" stroke="currentColor" stroke-width="3"/>
  <line x1="105" y1="40" x2="190" y2="20" stroke="currentColor" stroke-width="1" stroke-dasharray="4 3"/>
  <text x="196" y="24" font-size="13" fill="currentColor" font-family="system-ui, sans-serif">Pressure gauge: stop below 30 bar</text>
</svg>
```

The callout text is an STE label: a noun phrase, a colon, then a command with the number from the source.

## Delivery

- In the terminal: put the Mermaid fence or the SVG inline in the reply, caption under it, then the escalation line from SKILL.md (offer `--as html`).
- To keep or share: publish an artifact page through the Artifact tool. Load `artifact-design` first, as the html rung requires (see `html.md`). A Mermaid fence renders in the artifact as is.
- A file on disk only when the user asked for a file. Say which format and where it was written.

One diagram per answer unless the source has two independent mechanisms. Two diagrams that share parts should be one diagram.
