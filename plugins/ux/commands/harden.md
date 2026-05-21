---
description: "Make interfaces production-ready: error handling, i18n, edge cases, performance optimization, responsive adaptation. Replaces harden + optimize + adapt."
---

Strengthen interfaces against real-world usage: edge cases, errors, internationalization, performance bottlenecks, and cross-device adaptation.

**First**: Use the ux skill for design principles and anti-patterns.

## Assess

1. **Test with extreme inputs**: very long/short text, special characters (emoji, RTL), large numbers, many items (1000+), no data
2. **Test error scenarios**: network failures, API errors (400-500), validation, permissions, rate limiting, concurrent ops
3. **Test i18n**: long translations (German +30%), RTL, CJK characters, date/number formats, pluralization
4. **Measure performance**: Core Web Vitals (LCP, INP, CLS), bundle size, frame rate, network waterfall
5. **Test responsiveness**: mobile (320px), tablet, desktop, different inputs (touch, mouse, keyboard), orientations

## Text Overflow & i18n

**Overflow handling**:
- `text-overflow: ellipsis` for single-line truncation
- `-webkit-line-clamp` for multi-line
- `min-width: 0` on flex/grid items to allow shrinking
- `clamp()` for fluid typography

**i18n**:
- 30-40% space budget for translations. Use flexible containers, not fixed widths.
- Logical properties (`margin-inline-start`, `padding-inline`) for RTL support
- `Intl.DateTimeFormat` and `Intl.NumberFormat` for locale-aware formatting
- UTF-8 everywhere, test with CJK and emoji

## Error Handling

- Network errors: clear message + retry button + offline mode if applicable
- Form validation: inline errors near fields, specific messages, preserve user input
- API errors: handle each status (400=validation, 401=login redirect, 403=permission, 404=not found, 429=rate limit, 500=generic+support)
- Graceful degradation: core functionality works without JS, progressive enhancement

## Edge Cases

- Empty states with clear next action
- Loading states with context ("Loading your projects...")
- Large datasets: pagination or virtual scrolling
- Concurrent ops: prevent double-submit, handle race conditions
- Permission states: explain why, show path to access

## Performance

**Loading**:
- Modern image formats (WebP/AVIF), responsive `srcset`, lazy loading below fold
- Code splitting (route + component), tree shaking, dynamic imports for heavy components
- Critical CSS inline, async load the rest. Font `display: swap`, subset fonts.
- Preload critical assets, prefetch next pages

**Rendering**:
- Batch DOM reads then writes (avoid layout thrashing)
- `contain` for independent regions, `content-visibility: auto` for long lists
- Virtual scrolling for 100+ items
- Animate only `transform` and `opacity` (GPU-accelerated)

**React/framework**:
- `memo()` for expensive components, `useMemo`/`useCallback` where measured impact
- Virtualize long lists, code split routes
- Debounce/throttle expensive handlers

**Core Web Vitals targets**: LCP < 2.5s, INP < 200ms, CLS < 0.1
- LCP: optimize hero images, inline critical CSS, preload key resources
- INP: break long tasks, defer non-critical JS, web workers for heavy computation
- CLS: set dimensions on images/videos, `aspect-ratio`, don't inject content above existing

## Responsive Adaptation

**Mobile (320-767px)**: Single column, bottom navigation, 44px touch targets, 16px minimum text, progressive disclosure
**Tablet (768-1023px)**: Two-column, master-detail, support touch and pointer
**Desktop (1024+)**: Multi-column, hover states, keyboard shortcuts, max-width constraints

Use container queries when adapting to container size, media queries for viewport. Content-driven breakpoints over generic ones.

## Accessibility Resilience

- All functionality keyboard-accessible, logical tab order, focus management in modals
- ARIA labels, live regions for dynamic changes, semantic HTML
- `prefers-reduced-motion: reduce` disables animations
- Test in high contrast mode, don't rely only on color

## Verify

- Long text (100+ chars), emoji, RTL, CJK in all text fields
- Disable internet, throttle to 3G
- 1000+ items in lists
- Click submit 10 times rapidly
- Before/after Lighthouse scores
- Test on low-end Android, not just flagship devices
