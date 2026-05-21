---
description: "Improve UX details: copy clarity, onboarding flows, motion/animation, and moments of delight. Argument: copy (improve text), onboard (first-time UX), motion (animations), or delight (personality and joy). Replaces clarify + onboard + animate + delight."
argument-hint: "copy | onboard | motion | delight"
---

Refine specific UX dimensions. Pick the one that needs attention.

**First**: Use the ux skill for design principles and anti-patterns.

## MANDATORY PREPARATION

Gather context: target audience, brand personality, and what's appropriate for this domain. If you can't infer these confidently, STOP and ask via AskUserQuestion.

## Pick the focus

`$ARGUMENTS`:
- **copy** — Fix unclear UX writing, error messages, labels, instructions
- **onboard** — Design first-time user experiences, empty states, feature discovery
- **motion** — Add purposeful animations and micro-interactions
- **delight** — Add personality, joy, and unexpected touches
- **empty** — Assess the interface and recommend which focus

## Copy

Identify and fix unclear interface text.

**Error messages**: Explain what went wrong in plain language, suggest how to fix it, don't blame the user. Bad: "Error 403: Forbidden". Good: "You don't have permission to view this page. Contact your admin for access."

**Form labels**: Specific names, not generic. Show format expectations with examples. Explain why you're asking.

**Buttons/CTAs**: Describe the action specifically (verb + noun). "Create account" not "Submit". "Save changes" not "OK".

**Help text**: Add value beyond the label. Answer the implicit question. Keep brief.

**Empty states**: Explain what will appear, why it's valuable, clear CTA to create first item. Never just "No items."

**Success messages**: Confirm what happened. Explain what's next. "Settings saved! Changes take effect immediately."

**Loading states**: Set expectations (how long?), explain what's happening, show progress.

**Confirmation dialogs**: State the specific action, explain consequences. "Delete 'Project Alpha'? This can't be undone." Buttons: "Delete project" not "Yes."

**Principles**: Be specific, concise, active voice, human, helpful, consistent. Never: jargon, blame, vagueness, humor for errors, placeholder-only labels.

## Onboard

Get users to value as quickly as possible.

**Principles**: Show don't tell. Make it optional (let experienced users skip). Teach 20% that delivers 80%. Context over ceremony (teach features when users need them). Respect intelligence.

**Welcome**: Clear value proposition, time estimate, option to skip.
**Account setup**: Minimal required info, explain why you're asking, smart defaults.
**First success**: Guide to one real accomplishment, pre-populated examples/templates, celebrate completion.

**Empty states**: Description of what will appear + why it's valuable + CTA + visual interest + help link. Types: first use (emphasize value), user cleared (light touch), no results (suggest different query), no permissions (explain why), error (retry option).

**Feature discovery**: Contextual tooltips at point of use (brief, dismissable, "Don't show again"). Progressive disclosure — unlock complexity gradually. Badges on new/unused features.

**Guided tours** (for complex interfaces): Spotlight elements, 3-7 steps max, allow skip, make replayable. Interactive > passive.

Track "seen" states in localStorage. Don't show same onboarding twice.

## Motion

Add animations that enhance understanding and provide feedback.

**Find opportunities**: Missing feedback (actions without acknowledgment), jarring transitions (instant state changes), unclear relationships, lack of delight.

**Strategy**: Pick ONE hero moment. Layer: feedback (which interactions need acknowledgment?) → transitions (which state changes need smoothing?) → delight (where can we surprise?).

**Entrances**: Staggered reveals (100-150ms delays), fade + slide combinations, scroll-triggered via IntersectionObserver.

**Micro-interactions**: Button hover (scale 1.02-1.05, color shift), click (quick scale 0.95→1), form focus (border transition, subtle glow), toggle slide + color.

**State transitions**: Show/hide with fade + slide (200-300ms), expand/collapse with height + icon rotation, loading skeletons, success/error color transitions.

**Timing**: 100-150ms for instant feedback, 200-300ms for state changes, 300-500ms for layout changes, 500-800ms for entrances. Exits at 75% of entrance duration.

**Easing**: `ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1)` for smooth. `ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1)` for confident. Never bounce or elastic.

**Performance**: Only animate `transform` and `opacity`. `will-change` sparingly. Target 60fps. `requestAnimationFrame` for JS animations.

**CRITICAL**: Always `@media (prefers-reduced-motion: reduce)` to disable/simplify all motion.

## Delight

Add personality that enhances usability, never obscures it.

**Find moments**: Success states, empty states, loading waits, achievements, interactions, errors (soften frustration), easter eggs.

**Principles**: Delight amplifies, never blocks (< 1s, skippable). Surprise and discovery (hide details for users to find). Appropriate to context (match emotional moment). Compound over time (vary responses, reveal layers).

**Techniques**:
- Satisfying button press (translateY on active, lift on hover)
- Playful loading messages ("Teaching robots to dance...")
- Success animations (checkmark draw, confetti for milestones)
- Encouraging empty states ("Your canvas awaits.")
- Contextual personality in copy (match brand — banks can be warm, not wacky)
- Custom illustrations for empty/error/loading states
- Easter eggs (Konami code, console messages, hover reveals)
- Seasonal/time-of-day touches (subtle)

**Sound** (when appropriate): Subtle notification/success/error cues. Respect system sound settings, provide mute, keep quiet.

**Never**: Delay core functionality for delight. Force users through delight moments. Use delight to hide poor UX. Make every interaction delightful (special moments should be special).

## Verify

- **Copy**: Comprehensible without context? Actionable? As short as possible while clear?
- **Onboard**: Users reach "aha moment" quickly? Completion rate acceptable? Skippable?
- **Motion**: 60fps? Feels natural? Reduced motion works? Adds value?
- **Delight**: Still pleasant after 100th time? Doesn't block? Matches brand? Accessible?
