---
description: "Final quality pass: alignment, spacing, consistency, design system adherence, typography, interaction states, and code cleanup. Replaces polish + normalize + distill."
---

Meticulous final pass — catch the details that separate good from great. Includes design system normalization and complexity reduction.

**First**: Use the ux skill for design principles and anti-patterns.

**CRITICAL**: Polish is the last step. Don't polish work that isn't functionally complete.

## Pre-Polish Assessment

- Is it functionally complete?
- Does a design system exist? (Search for design system docs, component libraries, style guides)
- What's the quality bar? (MVP vs flagship)
- Where are the obvious inconsistencies?

## Design System Normalization

If a design system exists:
- Replace custom implementations with design system components
- Replace hard-coded colors/spacing/typography with design tokens
- Match animation timing, easing, and interaction patterns to established conventions
- Match responsive breakpoints and patterns
- Match progressive disclosure and information hierarchy

If deviations from the design system exist, fix them. If the design system doesn't cover a pattern, note it for extraction (use `/ux:reshape extract`).

## Complexity Reduction

Before polishing, simplify:
- **One primary action per view** — reduce competing buttons and CTAs
- **Progressive disclosure** — hide complexity behind clear entry points
- **Remove redundancy** — if it's said elsewhere, don't repeat it
- **Flatten structure** — reduce nesting, remove unnecessary containers and cards
- **Shorter copy** — cut every sentence in half, then do it again
- **Fewer colors, fonts, sizes** — use the minimum that serves hierarchy
- **Smart defaults** — make common choices automatic

## Polish Systematically

### Visual Alignment & Spacing
- Everything lines up to grid. Use spacing scale consistently (no random 13px gaps).
- Optical alignment for visual weight (icons may need offset).
- Responsive consistency at all breakpoints.

### Typography
- Same elements use same sizes/weights throughout
- Line length 45-75 chars for body text
- No widows/orphans, appropriate hyphenation
- Font loading — no FOUT/FOIT flashes

### Color & Contrast
- All text meets WCAG contrast standards
- No hard-coded colors — all use design tokens
- Works in all theme variants
- Tinted neutrals (never pure gray), never gray on colored backgrounds

### Interaction States
Every interactive element needs: default, hover, focus, active, disabled, loading, error, success. Missing states create broken experiences.

### Transitions
- All state changes animated (150-300ms)
- Consistent easing: ease-out-quart/quint/expo. Never bounce or elastic.
- 60fps, only animate transform and opacity
- Respects `prefers-reduced-motion`

### Content & Copy
- Consistent terminology throughout
- Consistent capitalization (Title Case vs Sentence case)
- No typos, appropriate length, punctuation consistency
- Active voice ("Save changes" not "Changes will be saved")

### Icons & Images
- Consistent style and sizing across all icons
- Optical alignment with adjacent text
- Alt text on all images
- No layout shift on image load (aspect ratios set)

### Forms
- All inputs properly labeled
- Clear required indicators
- Helpful error messages
- Logical tab order
- Consistent validation timing

### Edge States
- Loading states with context
- Welcoming empty states with clear next action
- Helpful error states with recovery paths
- Graceful handling of long content and missing data

## Code Cleanup

- Remove console.logs, commented code, unused imports
- Consistent naming conventions
- No TypeScript `any` or ignored errors
- Proper ARIA labels and semantic HTML

## Checklist

- [ ] Visual alignment perfect at all breakpoints
- [ ] Spacing uses design tokens consistently
- [ ] Typography hierarchy consistent
- [ ] All interactive states implemented
- [ ] All transitions smooth (60fps)
- [ ] Copy consistent and polished
- [ ] Icons consistent and properly sized
- [ ] Forms properly labeled and validated
- [ ] Error/loading/empty states helpful
- [ ] Touch targets 44px minimum
- [ ] Contrast meets WCAG AA
- [ ] Keyboard navigation works
- [ ] Focus indicators visible
- [ ] No console errors
- [ ] No layout shift on load
- [ ] Reduced motion respected
- [ ] Code clean (no TODOs, console.logs)

Use it yourself before marking done.
