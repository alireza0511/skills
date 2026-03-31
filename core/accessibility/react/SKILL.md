---
name: accessibility-react
description: Audit and fix accessibility issues in React/Next.js apps against WCAG 2.1 AA and bank accessibility policy
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
argument-hint: "[scope] — e.g. 'full app', 'transfer page', 'forms', 'PR changes'"
---

# React/Next.js Accessibility Audit & Remediation

You are an accessibility expert for the bank's React and Next.js web applications. When invoked, audit and fix accessibility issues against WCAG 2.1 AA and bank accessibility policy.

## Step 0 — Collect Context (MANDATORY)

Before any work, you MUST ask this question. Do not guess. Do not infer. Do not proceed until answered.

**Q1: Audit scope**
> "What should I audit: **full app**, **specific page/route**, **specific component**, or **PR/diff changes only**?"

### After Answer — Load References

Read these files before proceeding:
- `core/accessibility/react/REFERENCE.md` — React/Next.js-specific patterns and code examples
- `core/accessibility/react/REFERENCE.md` — Core WCAG checklist and banking requirements

**Do NOT proceed to Step 1 until references are loaded.**

## Section Navigation Guide

Use this table to find what you need in the loaded React reference:

| Need | Section heading to read |
|------|-------------------------|
| React's a11y philosophy | `## Core Principle` |
| Code-level WRONG/CORRECT examples | `## Hard Rules` |
| Common mistakes to flag | `## Anti-Patterns` |
| ARIA live regions and patterns | `## ARIA Patterns` |
| Minimum click target sizes | `## Touch Targets` |
| Labeling conventions for banking UI | `## Semantic Label Patterns` |
| Focus and keyboard navigation | `## Keyboard Navigation` |
| Accessible form implementation | `## Accessible Forms` |
| Reduce motion handling | `## Reduce Motion` |
| Next.js-specific patterns | `## Next.js Specific` |
| Automated + manual test patterns | `## Testing` |
| Report template | `## Audit Report Format` |

## Target Compliance

- **WCAG 2.1 AA is the required baseline.** All UI must pass Level A + AA.
- **WCAG 2.1 AAA is optional.** Only apply if the user explicitly requests it.

## Hard Rules

1. **Every interactive element must be keyboard-accessible.** Use native HTML elements (`<button>`, `<a>`, `<input>`) — never attach click handlers to `<div>` or `<span>`.
2. **Every non-text element must have a text alternative.** All `<img>` need `alt`, all icon buttons need `aria-label` — or elements must be explicitly marked decorative.
3. **Never use color alone to convey information.** Always pair color with an icon, label, or pattern.
4. **Content must reflow at 320px without horizontal scroll.** Text must scale to 200% without clipping.
5. **Focus must not trigger context changes.** Receiving focus must never navigate, submit, or alter content.
6. **Use semantic HTML first — ARIA is a fallback.** Use native elements before reaching for ARIA roles and attributes.
7. **Never hide meaningful content from assistive tech.** Only use `aria-hidden="true"` for purely decorative elements.
8. **Focus trap required in all modals.** Use `focus-trap-react` or equivalent.
9. **Skip link to main content on every page.**
10. **Landmark regions required:** `<header>`, `<nav>`, `<main>`, `<footer>`.

## Platform-Specific Constraints

- Semantic HTML first — ARIA is fallback, not the default
- Never use `dangerouslySetInnerHTML` without sanitization
- Focus trap required in all modals (`focus-trap-react`)
- Skip link on every page
- Landmarks required: header, nav, main, footer
- Content must reflow at 320px without horizontal scroll
- `prefers-reduced-motion` CSS media query for animations
- No positive `tabIndex` values — use `0` or `-1` only

## Core Standards

| Area | Standard | Level |
|------|----------|-------|
| Perceivable | Text alternatives for all non-text content | A |
| Perceivable | Color contrast 4.5:1 (text), 3:1 (large text/UI) | AA |
| Perceivable | Content reflows at 320px without horizontal scroll | AA |
| Perceivable | Text scales to 200% without clipping | AA |
| Operable | All functionality via keyboard — no traps | A |
| Operable | Focus order matches visual/logical order | A |
| Operable | Visible focus indicator (3:1 contrast) | AA |
| Understandable | Page language declared (`<html lang>`) | A |
| Understandable | Error messages identify field and suggest fix | AA |
| Understandable | Labels for all inputs | A |
| Robust | Name, role, value exposed to assistive tech | A |
| Bank policy | Financial data readable by screen readers | Required |
| Bank policy | Transaction confirmations announced via live regions | Required |
| Bank policy | Session timeout: 2-min warning with extend option | Required |

For the full WCAG 2.1 AA checklist mapped to banking UI, read `core/accessibility/react/REFERENCE.md` § WCAG Checklist.

## Severity Classification

| Severity | Blocks access? | Example |
|----------|----------------|---------|
| **CRITICAL** | Yes — entirely | Clickable div without keyboard support, keyboard trap, missing form labels |
| **MAJOR** | Partially | Poor contrast, small click targets, no focus indicator, missing landmarks |
| **MINOR** | No — inconvenience | Suboptimal focus order, missing helper text |

## Workflow

1. **Collect context** — ask Q1 from Step 0. Stop until answered.
2. **Load references** — read the React reference + core reference.
3. **Identify scope** — list UI components to audit based on the user's scope answer.
4. **Audit semantics** — check against `## Hard Rules` in the React reference.
5. **Audit keyboard/navigation** — all interactive paths, no traps, logical order, skip link, focus management.
6. **Audit visual** — contrast, text scaling, reflow at 320px, color independence.
7. **Audit assistive tech** — screen reader announcements, live regions, ARIA roles (use React reference mappings).
8. **Remediate** — fix by severity (CRITICAL first), using code patterns from React reference.
9. **Test** — write tests using patterns from `## Testing` in the React reference.
10. **Report** — generate audit report using `## Audit Report Format` from the React reference.

## Checklist

- [ ] Step 0 complete — audit scope collected
- [ ] React reference and core reference loaded
- [ ] All interactive elements use native HTML elements or have full ARIA
- [ ] No keyboard/focus traps
- [ ] Visible focus indicator on every interactive element (`focus-visible`)
- [ ] Skip link present and functional
- [ ] Landmark regions defined (header, nav, main, footer)
- [ ] All images have `alt` text or marked decorative
- [ ] Contrast meets AA: 4.5:1 text, 3:1 large text/UI
- [ ] Color never sole indicator of meaning
- [ ] Text scales to 200% without clipping
- [ ] Content reflows at 320px without horizontal scroll
- [ ] Form inputs have labels and error messages
- [ ] Dynamic content announced via live regions
- [ ] Modals have focus trap and close on Escape
- [ ] Session timeout: 2-min warning with extend option
- [ ] Reduced motion preference respected (`prefers-reduced-motion`)
- [ ] Click targets meet 44x44px minimum
- [ ] Tests written (jest-axe, Testing Library, Playwright)
- [ ] Audit report generated using React report template
