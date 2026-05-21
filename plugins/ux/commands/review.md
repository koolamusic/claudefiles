---
description: "Evaluate interface quality: systematic audit (a11y, perf, theming, responsive) and design critique (hierarchy, IA, emotion, composition). Produces a prioritized report with severity ratings. Replaces audit + critique."
argument-hint: "Optional area or feature to focus on"
---

Run a combined quality audit and design critique. Two lenses on the same interface — systematic checklist + design-director judgment.

**First**: Use the ux skill for design principles and anti-patterns.

## Part 1: AI Slop Detection (CRITICAL)

**Start here.** Does this look like every other AI-generated interface? Check against ALL the DON'T guidelines in the ux skill. Look for: AI color palette (cyan-on-dark, purple-blue gradients), gradient text, glassmorphism, hero metrics with big numbers, identical card grids, generic fonts (Inter, Roboto), neon accents on dark backgrounds, bounce easing. Be brutally honest.

## Part 2: Design Critique

Evaluate as a design director:

- **Visual hierarchy** — Does the eye flow to the most important element first? Is there one clear primary action?
- **Information architecture** — Is the structure intuitive? Too many choices at once?
- **Emotional resonance** — What emotion does this evoke? Is that intentional? Does it match the brand?
- **Discoverability** — Are interactive elements obviously interactive? Would a user know what to do?
- **Composition** — Does the layout feel balanced? Is whitespace intentional? Is there visual rhythm?
- **Typography** — Does the type hierarchy signal reading order? Is body text comfortable?
- **Color purpose** — Is color communicating meaning or just decorating?
- **States** — Empty, loading, error, success — are they designed or afterthoughts?
- **Microcopy** — Is the writing clear, concise, and human?

## Part 3: Systematic Audit

Run checks across:

**Accessibility** — Contrast ratios, ARIA, keyboard navigation, semantic HTML, focus indicators, form labels
**Performance** — Layout thrashing, expensive animations, missing lazy loading, bundle size, unnecessary re-renders
**Theming** — Hard-coded colors, broken dark mode, inconsistent tokens, theme switching issues
**Responsive** — Fixed widths, touch targets < 44px, horizontal scroll, text scaling, missing breakpoints

## Report Structure

```
### AI Slop Verdict
Pass/fail with specific tells.

### Overall Impression
Gut reaction — what works, what doesn't, single biggest opportunity.

### Critical Issues (top 3-5)
For each: what, why it matters, fix direction, which command to use.

### Detailed Findings by Severity
CRITICAL → HIGH → MEDIUM → LOW
Each: location, category, description, impact, recommendation.

### Systemic Patterns
Recurring problems across the interface.

### What's Working
2-3 things done well and why.

### Fix Plan
Map issues to commands:
- /ux:tune for visual intensity
- /ux:harden for resilience + performance
- /ux:polish for consistency + alignment
- /ux:refine for copy, motion, onboarding, delight
- /ux:reshape for responsive, simplification, extraction
```

**This is an audit, not a fix.** Document thoroughly. Use other commands to address findings.
