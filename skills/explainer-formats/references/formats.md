# Formats `/explain` can produce

`/explain <topic> --as <format>` or `explain <topic> as <format>`. `/explain formats` prints this file.

## Prose (`ste`)

- `ste --level light` (default): careful technical writing, STE word choices, no declarations.
- `ste --level 80`: the numeric limits, active voice and the substitution table; domain nouns stay free.
- `ste --level strict`: everything in ASD-STE100, every domain term declared as a technical name on first use.

## Diagram

Rendered in chat or an artifact:

- `mermaid`: flowchart, sequence, state, class, ER, Gantt or timeline as a fenced block.
- `svg`: an inline SVG figure with exact placement, callouts, and both themes.

Rendered by the visualizer as an animated HTML file, exportable to SVG, PNG, JPEG, WebP, GIF, MP4 or WebM (`--as <type>`):

Systems
- `architecture`: components and connections.
- `high-level`: 4-7 box overview for non-engineers.
- `deployment`: where things run (hosts, regions).
- `dependency`: what imports or depends on what.
- `architecture-delta`: what a change adds, removes or alters.
- `it-state`: current IT landscape with health status.
- `uml-class`: classes and interfaces.
- `er`: entities and cardinality.
- `db-schema`: tables and foreign-key columns.

Process
- `flowchart`: decisions and branches.
- `sequence`: messages between actors over time.
- `state`: states and transitions.
- `swimlane`: who does which step.
- `process`: short linear numbered steps.
- `data-flow`: data moving through stages.
- `journey`: user steps and an emotion curve.
- `timeline`: dated events.
- `gantt`: work over time.
- `kanban`: items by status.
- `story-map`: backbone and release slices.
- `loop`: a reinforcing cycle or flywheel.

Data platform
- `medallion`: bronze, silver and gold layers.
- `dp-integration`: sources, integration, platform, serving.
- `dp-security-matrix`: roles by data access.

Structure
- `tree`: parent to children.
- `org-chart`: people and teams.
- `nested`: containment and scopes.
- `layers`: a stack.
- `venn`: overlaps.
- `pyramid`: ranking (`funnel` variant for drop-off).
- `quadrant`: a 2x2.
- `fishbone`: root causes.
- `wardley`: evolution by visibility.

Charts
- `bar`: compare amounts (`dumbbell`, `marimekko` variants).
- `line`: change over time (`slopegraph`, `bump`, `streamgraph`, `ridgeline` variants).
- `scatter`: two measures (`bubble`, `beeswarm` variants).
- `waterfall`: a running total.
- `treemap`: part of a whole.
- `heatmap`: an intensity grid.
- `radar`: a profile on shared axes.
- `polar`: cyclical values.
- `sankey`: flow volumes.

Other named variants: `quadrant-consultant`, `loop-terminal`, `sequence-oauth`, `state-lifecycle`, `tree-block-decomposition`, `high-level-vertical`.

## HTML

- `html`: a standalone explainer page, published as an artifact through the Artifact tool.
- `html` to a public page: the same page served through the `publish-page` skill when the reader wants a link outside Claude.

## Video

- `video`: a narrated Manim explainer, one scene per beat, published as an artifact player page.
