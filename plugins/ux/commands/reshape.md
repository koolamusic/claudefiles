---
description: "Restructure interfaces: responsive adaptation, simplification, or component extraction. Argument: responsive (cross-device), simplify (reduce complexity), or extract (design system extraction). Replaces adapt + distill + extract."
argument-hint: "responsive | simplify | extract"
---

Restructure an interface without changing its visual identity. Three modes.

**First**: Use the ux skill for design principles and anti-patterns.

## MANDATORY PREPARATION

Gather context: target audience, use cases, and what's truly essential vs nice-to-have. If you can't infer these confidently, STOP and ask via AskUserQuestion.

## Pick the mode

`$ARGUMENTS`:
- **responsive** — Adapt to work across screen sizes, devices, and input methods
- **simplify** — Strip to essence, remove unnecessary complexity
- **extract** — Pull reusable components and design tokens into the design system
- **empty** — Assess the interface and recommend which mode

## Responsive

Rethink the experience for each context. Adaptation is not just scaling.

**Mobile (320-767px)**:
- Single column, vertical stacking, full-width components
- Bottom navigation, hamburger for complex nav
- Touch targets 44px min, thumb-first design
- Progressive disclosure, shorter text, 16px minimum
- Swipe gestures where appropriate, bottom sheets over dropdowns

**Tablet (768-1023px)**:
- Two-column, master-detail, side panels
- Support both touch and pointer
- Adaptive based on orientation

**Desktop (1024+)**:
- Multi-column, side navigation always visible
- Hover states, keyboard shortcuts, right-click menus, drag-and-drop
- Max-width constraints (don't stretch to 4K)
- Show more information upfront, richer visualizations

**Techniques**:
- CSS Grid/Flexbox for layout reflow
- Container queries for component-level adaptation
- `clamp()` for fluid sizing
- Responsive images (`srcset`, `picture`)
- Content-driven breakpoints over generic ones

**Print/Email**: If applicable — proper page breaks, inline CSS for email, narrow width (600px max), table-based email layouts.

**Never**: Hide core functionality on mobile. Use different IA across contexts. Forget landscape orientation. Use generic breakpoints blindly.

Test on real devices, not just browser DevTools.

## Simplify

Remove obstacles between users and their goals. Simplicity is not feature-less — it's obstacle-less.

**Find the essence**: What's the ONE primary user goal? What's the 20% that delivers 80% of value?

**Information architecture**:
- Reduce scope — remove secondary actions and redundant information
- Progressive disclosure — hide complexity behind clear entry points
- Combine related actions — merge similar buttons, consolidate forms
- ONE primary action, few secondary, everything else tertiary or hidden

**Visual simplification**:
- 1-2 colors plus neutrals, not 5-7
- One font family, 3-4 sizes, 2-3 weights
- Remove decorations that don't serve hierarchy (borders, shadows, backgrounds)
- Flatten nesting, remove unnecessary containers — never nest cards inside cards

**Layout**: Linear vertical flow where possible. Remove sidebars (move content inline or hide). Generous whitespace. Consistent alignment.

**Interaction**: Fewer choices (paradox of choice). Smart defaults. Inline actions over modal flows. Reduce steps.

**Content**: Cut words ruthlessly. Active voice. No jargon. Scannable structure. Remove redundant copy (headers restating intros).

**Code**: Remove dead CSS/components. Flatten component trees. Consolidate similar styles. Reduce component variants (3 cover 90% of cases).

**Never**: Remove necessary functionality. Sacrifice accessibility. Make things so simple they're unclear. Eliminate all hierarchy.

## Extract

Pull reusable patterns into the design system. Extract what's clearly reusable now, not everything that might someday be.

**Discover**:
1. Find the design system / component library / shared UI directory. Understand its structure, conventions, tokens.
2. Identify: repeated components (3+ uses), hard-coded values that should be tokens, inconsistent variations of the same concept, reusable layout/composition/interaction patterns.
3. Assess value: Is it used 3+ times? Would systematizing improve consistency? General vs context-specific?

**Extract**:
- **Components**: Clear props API with sensible defaults, proper variants, accessibility built in, documentation.
- **Design tokens**: Clear naming (primitive vs semantic), proper hierarchy, documented usage.
- **Patterns**: When to use, code examples, variations.

**Migrate**: Find all instances of extracted patterns. Replace with shared version. Test visual/functional parity. Delete old implementations.

**Never**: Extract one-off context-specific implementations. Create components so generic they're useless. Skip TypeScript types. Create tokens for every single value.

## Verify

- **Responsive**: Works on real devices? Touch targets sufficient? Content adapts logically? Core functionality accessible everywhere?
- **Simplify**: Faster task completion? Reduced cognitive load? All necessary features still accessible? Clearer hierarchy?
- **Extract**: Shared versions match originals? All instances migrated? Dead code removed? Design system docs updated?
