---
description: "Adjust visual intensity: make designs bolder, quieter, or more colorful. Argument: bolder (amplify safe designs), quieter (tone down aggressive designs), or colorize (add strategic color to monochromatic designs). Replaces bolder + quieter + colorize."
argument-hint: "bolder | quieter | colorize"
---

Adjust the visual intensity dial. Three directions, one skill.

**First**: Use the ux skill for design principles and anti-patterns.

## MANDATORY PREPARATION

Gather context: target audience, brand personality/tone, and existing design direction. If you can't infer these confidently from the codebase, STOP and ask via AskUserQuestion. Guessing leads to generic AI slop.

## Pick the direction

`$ARGUMENTS` determines the mode:
- **bolder** — Amplify safe or boring designs. More impact, more personality, more drama.
- **quieter** — Tone down aggressive designs. More refined, more sophisticated, easier on the eyes.
- **colorize** — Add strategic color to monochromatic designs. More warmth, more meaning, more engagement.
- **empty** — Assess the interface and recommend which direction.

## Bolder

Increase visual impact while maintaining usability. "Bolder" means distinctive and confident, not chaotic.

**WARNING**: AI slop trap — when making things "bolder," don't default to cyan/purple gradients, glassmorphism, neon accents, or gradient text. These are generic, not bold.

- **Typography**: Replace generic fonts with distinctive choices. Extreme scale jumps (3-5x, not 1.5x). Pair 900 weights with 200 weights.
- **Color**: Increase saturation. Bold palette with unexpected combinations. Let one color own 60%. Tinted neutrals.
- **Space**: Extreme scale jumps. Break the grid intentionally. Asymmetric layouts. Generous whitespace (100-200px gaps).
- **Effects**: Dramatic shadows for elevation. Texture and depth (grain, halftone, duotone). Custom decorative elements.
- **Motion**: Staggered entrance choreography. Scroll-triggered effects. Satisfying hover feedback. Use ease-out-quart/quint/expo, never bounce.
- **Composition**: Clear focal point with dramatic treatment. Full-bleed elements. Unexpected proportions (70/30, 80/20).

## Quieter

Reduce visual intensity while maintaining character. "Quieter" means refined and sophisticated, not boring.

- **Color**: Reduce saturation to 70-85%. Soften palette to muted tones. Fewer colors, more neutrals. Tinted grays, never pure gray.
- **Weight**: Reduce font weights (900→600, 700→500). Decrease sizes where appropriate. Use space and weight for hierarchy instead of color.
- **Simplification**: Remove decorative gradients, shadows, patterns that don't serve purpose. Flatten layering. Clean up blur effects and glows.
- **Motion**: Shorter distances (10-20px not 40px). Remove decorative animations. Keep only functional motion. Reduce or remove if not clearly purposeful.
- **Composition**: Smaller scale jumps for calmer feel. Bring elements back to grid. Consistent spacing rhythm.

## Colorize

Introduce color strategically. More color ≠ better. Every color should have a purpose.

- **Palette**: 2-4 colors max beyond neutrals. Dominant (60%), secondary (30%), accent (10%). Use OKLCH for perceptually uniform scales.
- **Semantic color**: Success (green), error (red/pink), warning (amber), info (blue). Status badges, progress indicators.
- **Accent application**: Primary action buttons, links, key icons, section headers, hover states.
- **Surfaces**: Replace pure gray backgrounds with warm/cool tinted neutrals (oklch with 0.01 chroma). Subtle background colors to separate areas. Tinted cards for warmth.
- **Data**: Color to encode categories/values in charts. Heatmaps, comparison coding.
- **Accents**: Colored left/top borders on cards. Colored dividers. Focus rings matching brand.
- **Never**: Gray text on colored backgrounds (use a shade of the background color). Pure black/pure white for large areas. Purple-blue gradients. Color as sole indicator (a11y).

## Verify

- **Bolder**: Does it look AI-generated? If yes, start over. Is it memorable? Still functional?
- **Quieter**: Still has character? Better for extended reading? Feels premium, not generic?
- **Colorize**: Better hierarchy? Clearer meaning? More engaging? WCAG-compliant?
